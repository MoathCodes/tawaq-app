// ---------------------------------------------------------------------------
// desktop_tray – Linux native implementation
//
// Uses libayatana-appindicator (or legacy libappindicator) with GtkMenu.
// The deprecation g_warning() from newer libayatana-appindicator versions
// is silently suppressed via a GLib log handler — no output to stderr.
//
// Three design rules prevent "corrupted size vs. prev_size" heap corruption
// from libdbusmenu:
//
//   1.  The GtkMenu is created once and NEVER replaced.  Only its children
//       are swapped when the Dart side calls setContextMenu.
//
//   2.  app_indicator_set_menu() is re-called on every setContextMenu (tawaq
//       local patch) so live label/checkbox updates propagate to the dbusmenu
//       host. The plugin keeps a sunk ref on g_menu so the unref inside
//       set_menu never destroys our static menu pointer.
//
//   3.  Old GtkMenuItems are removed from the container, ref-counted, and
//       queued for deferred destruction via g_idle_add().
// ---------------------------------------------------------------------------

#include "include/desktop_tray/desktop_tray_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#ifdef HAVE_AYATANA
#include <libayatana-appindicator/app-indicator.h>
#else
#include <libappindicator/app-indicator.h>
#endif

#include <cstring>

// ----- GObject boilerplate --------------------------------------------------

#define DESKTOP_TRAY_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), desktop_tray_plugin_get_type(), \
                              DesktopTrayPlugin))

struct _DesktopTrayPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(DesktopTrayPlugin, desktop_tray_plugin, g_object_get_type())

// ----- Global state (one tray per process) ----------------------------------

static DesktopTrayPlugin* g_plugin = nullptr;

static AppIndicator* g_indicator = nullptr;
static GtkWidget*    g_menu      = nullptr;
static gchar*        g_stashed_title = nullptr;

static bool g_tray_unavailable = false;

// Orphaned widgets awaiting deferred destruction.
static GList* g_orphans       = nullptr;
static bool   g_flush_pending = false;

// ----- GLib log handler: completely suppress appindicator warnings ----------

// libayatana-appindicator emits a deprecation g_warning() at construction.
// This handler silently swallows it so it never appears on stderr.
static void silent_log_handler(const gchar* /*log_domain*/,
                               GLogLevelFlags /*log_level*/,
                               const gchar* /*message*/,
                               gpointer /*user_data*/) {
  // Intentionally empty — suppress all messages from this domain.
}

// ----- D-Bus availability check ---------------------------------------------

static gboolean is_status_notifier_available() {
  GError* error = nullptr;
  GDBusConnection* conn =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (conn == nullptr) {
    if (error) {
      g_printerr("desktop_tray: cannot connect to session bus: %s\n",
                  error->message);
      g_error_free(error);
    }
    return FALSE;
  }

  GVariant* result = g_dbus_connection_call_sync(
      conn,
      "org.freedesktop.DBus",
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      "NameHasOwner",
      g_variant_new("(s)", "org.kde.StatusNotifierWatcher"),
      G_VARIANT_TYPE("(b)"),
      G_DBUS_CALL_FLAGS_NONE,
      2000,
      nullptr,
      &error);

  gboolean available = FALSE;
  if (result != nullptr) {
    g_variant_get(result, "(b)", &available);
    g_variant_unref(result);
  } else {
    if (error) {
      g_printerr("desktop_tray: D-Bus NameHasOwner failed: %s\n",
                  error->message);
      g_error_free(error);
    }
  }

  g_object_unref(conn);
  return available;
}

// ----- Deferred destruction -------------------------------------------------

static gboolean flush_orphans(gpointer /*unused*/) {
  GList* batch  = g_orphans;
  g_orphans     = nullptr;
  g_flush_pending = false;

  for (GList* it = batch; it != nullptr; it = g_list_next(it)) {
    GtkWidget* w = GTK_WIDGET(it->data);
    gtk_widget_destroy(w);
    g_object_unref(w);
  }
  g_list_free(batch);
  return G_SOURCE_REMOVE;
}

// ----- Menu helpers ---------------------------------------------------------

static GtkWidget* create_submenu(FlValue* args);

static void on_menu_item_activate(GtkMenuItem* /*item*/, gpointer user_data) {
  if (g_plugin == nullptr) return;
  const gint id = GPOINTER_TO_INT(user_data);

  g_autoptr(FlValue) data = fl_value_new_map();
  fl_value_set_string_take(data, "id", fl_value_new_int(id));
  fl_method_channel_invoke_method(g_plugin->channel,
                                  "onTrayMenuItemClick", data,
                                  nullptr, nullptr, nullptr);
}

static void populate_menu(GtkWidget* target, FlValue* items_value) {
  if (items_value == nullptr || fl_value_get_type(items_value) != FL_VALUE_TYPE_LIST) {
    return;
  }
  const size_t len = fl_value_get_length(items_value);
  for (size_t i = 0; i < len; i++) {
    FlValue* iv   = fl_value_get_list_value(items_value, i);
    const int id  = fl_value_get_int(fl_value_lookup_string(iv, "id"));
    const char* type  = fl_value_get_string(fl_value_lookup_string(iv, "type"));
    const char* label = fl_value_get_string(fl_value_lookup_string(iv, "label"));
    const bool disabled = fl_value_get_bool(fl_value_lookup_string(iv, "disabled"));

    if (strcmp(type, "separator") == 0) {
      gtk_menu_shell_append(GTK_MENU_SHELL(target),
                            gtk_separator_menu_item_new());
      continue;
    }

    GtkWidget* item = nullptr;

    if (strcmp(type, "checkbox") == 0) {
      item = gtk_check_menu_item_new_with_label(label);
      FlValue* cv = fl_value_lookup_string(iv, "checked");
      if (cv != nullptr) {
        gtk_check_menu_item_set_active(GTK_CHECK_MENU_ITEM(item),
                                       fl_value_get_bool(cv));
      }
    } else {
      item = gtk_menu_item_new_with_label(label);
    }

    if (disabled) gtk_widget_set_sensitive(item, FALSE);

    if (strcmp(type, "submenu") == 0) {
      FlValue* sub = fl_value_lookup_string(iv, "submenu");
      if (sub != nullptr) {
        gtk_menu_item_set_submenu(GTK_MENU_ITEM(item), create_submenu(sub));
      }
    }

    g_signal_connect(G_OBJECT(item), "activate",
                     G_CALLBACK(on_menu_item_activate),
                     GINT_TO_POINTER(id));

    gtk_menu_shell_append(GTK_MENU_SHELL(target), item);
  }
}

static GtkWidget* create_submenu(FlValue* args) {
  FlValue* items = fl_value_lookup_string(args, "items");
  GtkWidget* sub = gtk_menu_new();
  populate_menu(sub, items);
  return sub;
}

static void clear_menu(GtkWidget* target) {
  GList* children = gtk_container_get_children(GTK_CONTAINER(target));
  for (GList* it = children; it != nullptr; it = g_list_next(it)) {
    GtkWidget* child = GTK_WIDGET(it->data);
    g_object_ref(child);
    gtk_container_remove(GTK_CONTAINER(target), child);
    g_orphans = g_list_prepend(g_orphans, child);
  }
  g_list_free(children);

  if (g_orphans != nullptr && !g_flush_pending) {
    g_flush_pending = true;
    g_idle_add(flush_orphans, nullptr);
  }
}

static void ensure_menu() {
  if (g_menu != nullptr && !GTK_IS_WIDGET(g_menu)) {
    g_menu = nullptr;
  }
  if (g_menu == nullptr) {
    g_menu = gtk_menu_new();
    // gtk_menu_new() returns a floating ref. Sink it so app_indicator_set_menu()
    // (which always unrefs its previous menu before re-binding) cannot drop the
    // last reference and leave g_menu dangling on the next setContextMenu call.
    g_object_ref_sink(g_menu);
  }
}

// ----- Icon path helper -----------------------------------------------------

static void split_icon_path(const char* icon_path,
                            gchar** out_dir,
                            gchar** out_name) {
  *out_dir  = g_path_get_dirname(icon_path);
  gchar* base = g_path_get_basename(icon_path);
  gchar* dot = g_strrstr(base, ".");
  if (dot != nullptr && dot != base) {
    *dot = '\0';
  }
  *out_name = base;
}

// ----- Tray title (maps Dart setToolTip to app_indicator_set_title) -----------

static void stash_indicator_title(const gchar* title) {
  g_free(g_stashed_title);
  g_stashed_title = (title != nullptr && title[0] != '\0')
                        ? g_strdup(title)
                        : nullptr;
}

static void apply_indicator_title() {
  if (g_indicator == nullptr || g_stashed_title == nullptr) return;
  app_indicator_set_title(g_indicator, g_stashed_title);
}

// ----- Method-channel handlers ----------------------------------------------

static FlMethodResponse* handle_check_available(FlValue* /*args*/) {
  gboolean avail = is_status_notifier_available();
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(avail)));
}

static FlMethodResponse* handle_destroy(FlValue* /*args*/) {
  if (g_indicator != nullptr) {
    app_indicator_set_status(g_indicator, APP_INDICATOR_STATUS_PASSIVE);
  }
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_set_icon(FlValue* args) {
  if (g_tray_unavailable) {
    return FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(false)));
  }

  const char* icon_path =
      fl_value_get_string(fl_value_lookup_string(args, "iconPath"));

  gchar* icon_dir  = nullptr;
  gchar* icon_name = nullptr;
  split_icon_path(icon_path, &icon_dir, &icon_name);

  ensure_menu();

  if (g_indicator == nullptr) {
    if (!is_status_notifier_available()) {
      g_printerr("desktop_tray: StatusNotifierWatcher not found on D-Bus, "
                  "skipping tray icon creation.\n");
      g_tray_unavailable = true;
      g_free(icon_dir);
      g_free(icon_name);
      return FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    g_indicator = app_indicator_new_with_path(
        "tawaq", icon_name,
        APP_INDICATOR_CATEGORY_APPLICATION_STATUS, icon_dir);
#pragma GCC diagnostic pop

    if (g_indicator == nullptr) {
      g_printerr("desktop_tray: app_indicator_new_with_path returned NULL.\n");
      g_tray_unavailable = true;
      g_free(icon_dir);
      g_free(icon_name);
      return FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }
  }

  app_indicator_set_icon_theme_path(g_indicator, icon_dir);
  app_indicator_set_status(g_indicator, APP_INDICATOR_STATUS_ACTIVE);
  app_indicator_set_icon_full(
      g_indicator, icon_name,
      g_stashed_title != nullptr ? g_stashed_title : "");
  apply_indicator_title();

  g_free(icon_dir);
  g_free(icon_name);

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_set_tooltip(FlValue* args) {
  // AppIndicator has no hover-tooltip API; map setToolTip to the panel title.
  FlValue* tool_tip_val = fl_value_lookup_string(args, "toolTip");
  const char* tool_tip =
      tool_tip_val != nullptr ? fl_value_get_string(tool_tip_val) : "";
  stash_indicator_title(tool_tip);
  apply_indicator_title();
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_set_context_menu(FlValue* args) {
  if (g_tray_unavailable) {
    return FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(false)));
  }

  ensure_menu();

  // 1. Remove old items (deferred destruction).
  clear_menu(g_menu);

  // 2. Populate with new items.
  FlValue* menu_val  = fl_value_lookup_string(args, "menu");
  FlValue* items_val = fl_value_lookup_string(menu_val, "items");
  populate_menu(g_menu, items_val);

  // 3. LOCAL PATCH (tawaq): re-export the menu on EVERY update, not just once.
  //    Upstream bound the menu a single time (g_menu_bound) to avoid heap
  //    corruption, but swapping children of an already-bound AppIndicator menu
  //    does not refresh in most dbusmenu hosts — labels/checkboxes went stale.
  //    Re-calling app_indicator_set_menu() with the SAME g_menu widget is
  //    refcount-safe (ref new == unref old) and the deferred clear_menu() above
  //    still prevents the libdbusmenu heap corruption the one-time bind guarded.
  if (g_indicator != nullptr) {
    app_indicator_set_menu(g_indicator, GTK_MENU(g_menu));

    // 4. Make new items visible.
    gtk_widget_show_all(g_menu);
  }

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_pop_up_context_menu(FlValue* /*args*/) {
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(true)));
}

// ----- Plugin plumbing ------------------------------------------------------

static void desktop_tray_plugin_handle_method_call(
    DesktopTrayPlugin* /*self*/,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args       = fl_method_call_get_args(method_call);

  if (strcmp(method, "checkAvailable") == 0) {
    response = handle_check_available(args);
  } else if (strcmp(method, "destroy") == 0) {
    response = handle_destroy(args);
  } else if (strcmp(method, "setIcon") == 0) {
    response = handle_set_icon(args);
  } else if (strcmp(method, "setToolTip") == 0) {
    response = handle_set_tooltip(args);
  } else if (strcmp(method, "setContextMenu") == 0) {
    response = handle_set_context_menu(args);
  } else if (strcmp(method, "popUpContextMenu") == 0) {
    response = handle_pop_up_context_menu(args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void desktop_tray_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(desktop_tray_plugin_parent_class)->dispose(object);
}

static void desktop_tray_plugin_class_init(DesktopTrayPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = desktop_tray_plugin_dispose;
}

static void desktop_tray_plugin_init(DesktopTrayPlugin* /*self*/) {}

static void method_call_cb(FlMethodChannel* /*channel*/,
                            FlMethodCall* method_call,
                            gpointer user_data) {
  DesktopTrayPlugin* plugin = DESKTOP_TRAY_PLUGIN(user_data);
  desktop_tray_plugin_handle_method_call(plugin, method_call);
}

void desktop_tray_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  // Install silent log handlers BEFORE any appindicator code runs.
  // This completely suppresses the "libayatana-appindicator is deprecated"
  // g_warning() — it never appears on stderr.
  g_log_set_handler("libayatana-appindicator",
                    (GLogLevelFlags)(G_LOG_LEVEL_WARNING |
                                    G_LOG_LEVEL_CRITICAL |
                                    G_LOG_LEVEL_MESSAGE),
                    silent_log_handler, nullptr);
  g_log_set_handler("libappindicator",
                    (GLogLevelFlags)(G_LOG_LEVEL_WARNING |
                                    G_LOG_LEVEL_CRITICAL |
                                    G_LOG_LEVEL_MESSAGE),
                    silent_log_handler, nullptr);
  g_log_set_handler("dbusmenu-glib",
                    (GLogLevelFlags)(G_LOG_LEVEL_WARNING |
                                    G_LOG_LEVEL_CRITICAL |
                                    G_LOG_LEVEL_MESSAGE),
                    silent_log_handler, nullptr);

  DesktopTrayPlugin* plugin = DESKTOP_TRAY_PLUGIN(
      g_object_new(desktop_tray_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "desktop_tray", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb,
      g_object_ref(plugin), g_object_unref);

  g_plugin = plugin;

  g_object_unref(plugin);
}

