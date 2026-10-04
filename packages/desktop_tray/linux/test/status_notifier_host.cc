// Native contract harness: real SNI and dbusmenu exports on a private test bus.
#include <gtk/gtk.h>
#include <libdbusmenu-glib/server.h>
#include <libdbusmenu-gtk/parser.h>

#include <memory>

#include "../status_notifier_item.h"

struct State {
  std::unique_ptr<StatusNotifierItem> tray;
  GMainLoop* loop;
  GtkWidget* menu;
  DbusmenuServer* server;
  int activations = 0;
  int selections = 0;
};

static void Control(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                    const gchar* method, GVariant*, GDBusMethodInvocation* call,
                    gpointer data) {
  auto* state = static_cast<State*>(data);
  if (g_str_equal(method, "Counts")) {
    g_dbus_method_invocation_return_value(
        call, g_variant_new("(ii)", state->activations, state->selections));
    return;
  }
  if (g_str_equal(method, "Update")) {
    state->tray->SetTitle("Next prayer · updated");
    GList* children = gtk_container_get_children(GTK_CONTAINER(state->menu));
    gtk_menu_item_set_label(GTK_MENU_ITEM(children->data), "Hide Tawaq");
    g_list_free(children);
    DbusmenuMenuitem* root = dbusmenu_gtk_parse_menu_structure(state->menu);
    dbusmenu_server_set_root(state->server, root);
    g_object_unref(root);
  } else if (g_str_equal(method, "Destroy")) {
    state->tray.reset();
  } else if (g_str_equal(method, "Quit")) {
    g_main_loop_quit(state->loop);
  }
  g_dbus_method_invocation_return_value(call, nullptr);
}

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);
  State state;
  state.loop = g_main_loop_new(nullptr, FALSE);
  state.menu = gtk_menu_new();
  g_object_ref_sink(state.menu);
  GtkWidget* row = gtk_menu_item_new_with_label("Show Tawaq");
  g_signal_connect(row, "activate",
                   G_CALLBACK(+[](GtkMenuItem*, gpointer data) {
                     static_cast<State*>(data)->selections++;
                   }),
                   &state);
  gtk_menu_shell_append(GTK_MENU_SHELL(state.menu), row);
  gtk_widget_show_all(state.menu);
  state.server = dbusmenu_server_new("/StatusNotifierItem/Menu");
  DbusmenuMenuitem* root = dbusmenu_gtk_parse_menu_structure(state.menu);
  dbusmenu_server_set_root(state.server, root);
  g_object_unref(root);
  state.tray =
      std::make_unique<StatusNotifierItem>([&]() { state.activations++; });
  g_autoptr(GError) error = nullptr;
  if (!state.tray->Start(argv[1], &error)) {
    g_printerr("%s\n", error->message);
    return 1;
  }
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  g_autoptr(GDBusNodeInfo) info = g_dbus_node_info_new_for_xml(R"(
    <node><interface name="me.tawaq.TrayTest">
      <method name="Counts"><arg type="i" direction="out"/><arg type="i" direction="out"/></method>
      <method name="Update"/><method name="Destroy"/><method name="Quit"/>
    </interface></node>)",
                                                               nullptr);
  const GDBusInterfaceVTable table = {Control, nullptr, nullptr, {nullptr}};
  g_dbus_connection_register_object(bus, "/Test", info->interfaces[0], &table,
                                    &state, nullptr, nullptr);
  g_print("%s\n", g_dbus_connection_get_unique_name(bus));
  fflush(stdout);
  g_main_loop_run(state.loop);
  state.tray.reset();
  g_object_unref(state.server);
  gtk_widget_destroy(state.menu);
  g_object_unref(state.menu);
  g_main_loop_unref(state.loop);
  return 0;
}
