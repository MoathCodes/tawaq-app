// Linux StatusNotifierItem activation with a GTK/dbusmenu context menu.
// Keep one sunk GtkMenu and defer removed widget destruction to preserve the
// existing libdbusmenu lifetime and live-update fixes.

#include "include/desktop_tray/desktop_tray_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include <libdbusmenu-glib/server.h>
#include <libdbusmenu-gtk/parser.h>
#include <memory>
#include "status_notifier_item.h"

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

static std::unique_ptr<StatusNotifierItem> g_item;
static DbusmenuServer* g_menu_server = nullptr;
static GtkWidget*    g_menu      = nullptr;
static gchar*        g_stashed_title = nullptr;


// Orphaned widgets awaiting deferred destruction.
static GList* g_orphans       = nullptr;
static bool   g_flush_pending = false;

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
    // Keep the menu alive across exported root updates.
    g_object_ref_sink(g_menu);
  }
}

static void export_menu() {
  if (g_menu_server == nullptr)
    g_menu_server = dbusmenu_server_new("/StatusNotifierItem/Menu");
  DbusmenuMenuitem* root = dbusmenu_gtk_parse_menu_structure(g_menu);
  dbusmenu_server_set_root(g_menu_server, root);
  if (root != nullptr) g_object_unref(root);
}

static void destroy_tray() {
  g_item.reset();
  g_clear_object(&g_menu_server);
  if (g_menu != nullptr) {
    clear_menu(g_menu);
    gtk_widget_destroy(g_menu);
    g_clear_object(&g_menu);
  }
  g_clear_pointer(&g_stashed_title, g_free);
}

// ----- Method-channel handlers ----------------------------------------------

static FlMethodResponse* handle_check_available(FlValue* /*args*/) {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(
      fl_value_new_bool(StatusNotifierItem::IsAvailable())));
}

static FlMethodResponse* handle_destroy(FlValue* /*args*/) {
  destroy_tray();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_set_icon(FlValue* args) {
  const char* path = fl_value_get_string(fl_value_lookup_string(args, "iconPath"));
  g_autoptr(GError) error = nullptr;
  if (g_item == nullptr) {
    ensure_menu();
    export_menu();
    auto item = std::make_unique<StatusNotifierItem>([]() {
      if (g_plugin != nullptr) {
        // SNI supplies activation, not physical down/up events. Map it to the
        // established completion callback so a single click activates once.
        fl_method_channel_invoke_method(g_plugin->channel, "onTrayIconMouseUp",
                                        nullptr, nullptr, nullptr, nullptr);
      }
    });
    if (!item->Start(path, &error)) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "TRAY_UNAVAILABLE", error->message, nullptr));
    }
    g_item = std::move(item);
  } else if (!g_item->SetIcon(path, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "ICON_LOAD_FAILED", error->message, nullptr));
  }
  if (g_stashed_title != nullptr) g_item->SetTitle(g_stashed_title);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_set_tooltip(FlValue* args) {
  const char* title = fl_value_get_string(fl_value_lookup_string(args, "toolTip"));
  g_free(g_stashed_title);
  g_stashed_title = g_strdup(title);
  if (g_item != nullptr) g_item->SetTitle(title);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
}

static FlMethodResponse* handle_set_context_menu(FlValue* args) {
  ensure_menu();
  clear_menu(g_menu);
  FlValue* menu = fl_value_lookup_string(args, "menu");
  populate_menu(g_menu, fl_value_lookup_string(menu, "items"));
  gtk_widget_show_all(g_menu);
  export_menu();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
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
  DesktopTrayPlugin* self = DESKTOP_TRAY_PLUGIN(object);
  if (g_plugin == self) {
    destroy_tray();
    g_plugin = nullptr;
  }
  g_clear_object(&self->channel);
  g_clear_object(&self->registrar);
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

