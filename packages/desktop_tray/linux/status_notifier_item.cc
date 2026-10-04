#include "status_notifier_item.h"

#include <cstring>
#include <utility>

namespace {
constexpr char kPath[] = "/StatusNotifierItem";
constexpr char kInterface[] = "org.kde.StatusNotifierItem";
constexpr char kWatcher[] = "org.kde.StatusNotifierWatcher";
constexpr char kMenuPath[] = "/StatusNotifierItem/Menu";
constexpr char kXml[] = R"XML(
<node><interface name="org.kde.StatusNotifierItem">
  <property name="Category" type="s" access="read"/>
  <property name="Id" type="s" access="read"/>
  <property name="Title" type="s" access="read"/>
  <property name="Status" type="s" access="read"/>
  <property name="WindowId" type="u" access="read"/>
  <property name="IconName" type="s" access="read"/>
  <property name="IconThemePath" type="s" access="read"/>
  <property name="IconPixmap" type="a(iiay)" access="read"/>
  <property name="OverlayIconName" type="s" access="read"/>
  <property name="OverlayIconPixmap" type="a(iiay)" access="read"/>
  <property name="AttentionIconName" type="s" access="read"/>
  <property name="AttentionIconPixmap" type="a(iiay)" access="read"/>
  <property name="AttentionMovieName" type="s" access="read"/>
  <property name="ToolTip" type="(sa(iiay)ss)" access="read"/>
  <property name="ItemIsMenu" type="b" access="read"/>
  <property name="Menu" type="o" access="read"/>
  <method name="Activate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
  <method name="SecondaryActivate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
  <method name="ContextMenu"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
  <method name="Scroll"><arg type="i" direction="in"/><arg type="s" direction="in"/></method>
  <signal name="NewTitle"/>
  <signal name="NewIcon"/>
  <signal name="NewIconThemePath"><arg type="s"/></signal>
  <signal name="NewToolTip"/>
  <signal name="NewStatus"><arg type="s"/></signal>
</interface></node>)XML";
}  // namespace

StatusNotifierItem::StatusNotifierItem(std::function<void()> activate)
    : activate_(std::move(activate)) {}

StatusNotifierItem::~StatusNotifierItem() {
  if (watcher_ != 0) g_bus_unwatch_name(watcher_);
  if (registration_ != 0)
    g_dbus_connection_unregister_object(connection_, registration_);
  g_clear_object(&connection_);
}

bool StatusNotifierItem::IsAvailable() {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) connection =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (connection == nullptr) return false;
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      connection, "org.freedesktop.DBus", "/org/freedesktop/DBus",
      "org.freedesktop.DBus", "NameHasOwner", g_variant_new("(s)", kWatcher),
      G_VARIANT_TYPE("(b)"), G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, &error);
  gboolean owned = FALSE;
  if (reply != nullptr) g_variant_get(reply, "(b)", &owned);
  return owned;
}

bool StatusNotifierItem::Start(const char* icon_path, GError** error) {
  if (!SetIcon(icon_path, error)) return false;
  connection_ = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, error);
  if (connection_ == nullptr) return false;
  g_autoptr(GDBusNodeInfo) info = g_dbus_node_info_new_for_xml(kXml, error);
  if (info == nullptr) return false;
  static const GDBusInterfaceVTable vtable = {
      MethodCall, GetProperty, nullptr, {nullptr}};
  registration_ = g_dbus_connection_register_object(
      connection_, kPath, info->interfaces[0], &vtable, this, nullptr, error);
  if (registration_ == 0) return false;
  // Register synchronously once so setIcon cannot report a usable tray before
  // the host has accepted it. Watcher restarts are registered asynchronously.
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      connection_, kWatcher, "/StatusNotifierWatcher", kWatcher,
      "RegisterStatusNotifierItem", g_variant_new("(s)", kPath), nullptr,
      G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, error);
  if (reply == nullptr) return false;
  watcher_ = g_bus_watch_name_on_connection(
      connection_, kWatcher, G_BUS_NAME_WATCHER_FLAGS_NONE, WatcherAppeared,
      nullptr, this, nullptr);
  return true;
}

void StatusNotifierItem::RegisterWithWatcher() {
  g_dbus_connection_call(
      connection_, kWatcher, "/StatusNotifierWatcher", kWatcher,
      "RegisterStatusNotifierItem", g_variant_new("(s)", kPath), nullptr,
      G_DBUS_CALL_FLAGS_NONE, 2000, nullptr,
      [](GObject* source, GAsyncResult* result, gpointer) {
        g_autoptr(GError) error = nullptr;
        g_autoptr(GVariant) reply = g_dbus_connection_call_finish(
            G_DBUS_CONNECTION(source), result, &error);
        if (error != nullptr)
          g_warning("desktop_tray: registration failed: %s", error->message);
      },
      nullptr);
}

void StatusNotifierItem::WatcherAppeared(GDBusConnection*, const gchar*,
                                         const gchar*, gpointer data) {
  static_cast<StatusNotifierItem*>(data)->RegisterWithWatcher();
}

bool StatusNotifierItem::SetIcon(const char* path, GError** error) {
  if (g_path_is_absolute(path) && !g_file_test(path, G_FILE_TEST_IS_REGULAR)) {
    g_set_error(error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND,
                "Tray icon not found: %s", path);
    return false;
  }
  g_autofree gchar* directory = g_path_get_dirname(path);
  g_autofree gchar* basename = g_path_get_basename(path);
  gchar* dot = g_strrstr(basename, ".");
  if (dot != nullptr && dot != basename) *dot = '\0';
  icon_name_ = basename;
  icon_directory_ = directory;
  Emit("NewIconThemePath", g_variant_new("(s)", icon_directory_.c_str()));
  Emit("NewIcon");
  return true;
}

void StatusNotifierItem::SetTitle(const char* title) {
  title_ = title;
  Emit("NewTitle");
  Emit("NewToolTip");
}

void StatusNotifierItem::Emit(const char* signal, GVariant* parameters) {
  if (connection_ == nullptr || registration_ == 0) {
    if (parameters != nullptr) g_variant_unref(g_variant_ref_sink(parameters));
    return;
  }
  g_dbus_connection_emit_signal(connection_, nullptr, kPath, kInterface, signal,
                                parameters, nullptr);
}

GVariant* StatusNotifierItem::Property(const char* name) {
  if (strcmp(name, "Category") == 0)
    return g_variant_new_string("ApplicationStatus");
  if (strcmp(name, "Id") == 0) return g_variant_new_string("tawaq");
  if (strcmp(name, "Status") == 0) return g_variant_new_string("Active");
  if (strcmp(name, "Title") == 0) return g_variant_new_string(title_.c_str());
  if (strcmp(name, "IconName") == 0)
    return g_variant_new_string(icon_name_.c_str());
  if (strcmp(name, "IconThemePath") == 0)
    return g_variant_new_string(icon_directory_.c_str());
  if (strcmp(name, "Menu") == 0) return g_variant_new_object_path(kMenuPath);
  if (strcmp(name, "ItemIsMenu") == 0) return g_variant_new_boolean(FALSE);
  if (strcmp(name, "WindowId") == 0) return g_variant_new_uint32(0);
  if (strcmp(name, "ToolTip") == 0)
    return g_variant_new(
        "(s@a(iiay)ss)", icon_name_.c_str(),
        g_variant_new_array(G_VARIANT_TYPE("(iiay)"), nullptr, 0),
        title_.c_str(), "");
  if (g_str_has_suffix(name, "Pixmap"))
    return g_variant_new_array(G_VARIANT_TYPE("(iiay)"), nullptr, 0);
  return g_variant_new_string("");
}

GVariant* StatusNotifierItem::GetProperty(GDBusConnection*, const gchar*,
                                          const gchar*, const gchar*,
                                          const gchar* name, GError**,
                                          gpointer data) {
  return static_cast<StatusNotifierItem*>(data)->Property(name);
}

void StatusNotifierItem::MethodCall(GDBusConnection*, const gchar*,
                                    const gchar*, const gchar*,
                                    const gchar* method, GVariant*,
                                    GDBusMethodInvocation* invocation,
                                    gpointer data) {
  auto* self = static_cast<StatusNotifierItem*>(data);
  if (strcmp(method, "Activate") == 0 ||
      strcmp(method, "SecondaryActivate") == 0) {
    self->activate_();
  } else if (strcmp(method, "ContextMenu") == 0) {
    // Hosts render the exported Menu themselves. Report unsupported so hosts
    // that try ContextMenu first can fall back to dbusmenu, also on Wayland.
    g_dbus_method_invocation_return_error(invocation, G_DBUS_ERROR,
                                          G_DBUS_ERROR_NOT_SUPPORTED,
                                          "Use the exported Menu");
    return;
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}
