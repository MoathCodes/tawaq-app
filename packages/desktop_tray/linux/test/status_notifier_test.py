#!/usr/bin/env python3
"""Exercise the native adapter with a fake tray host on a private session bus."""
import os
import select
import subprocess
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
context = GLib.MainContext.default()
registrations = []
xml = GLib.Variant
watcher_info = Gio.DBusNodeInfo.new_for_xml("""
<node><interface name="org.kde.StatusNotifierWatcher">
  <method name="RegisterStatusNotifierItem"><arg type="s" direction="in"/></method>
</interface></node>""")


def register(connection, sender, path, interface, method, arguments, invocation):
    registrations.append((sender, arguments.unpack()[0]))
    invocation.return_value(None)


bus.register_object("/StatusNotifierWatcher", watcher_info.interfaces[0], register, None, None)


def request_name(method):
    return bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus",
                         "org.freedesktop.DBus", method,
                         xml("(su)", ("org.kde.StatusNotifierWatcher", 0)) if method == "RequestName"
                         else xml("(s)", ("org.kde.StatusNotifierWatcher",)),
                         None, Gio.DBusCallFlags.NONE, 2000, None)


def pump_until(predicate):
    deadline = time.monotonic() + 5
    while not predicate():
        while context.pending():
            context.iteration(False)
        if time.monotonic() > deadline:
            raise AssertionError("Timed out waiting for native tray state")
        time.sleep(0.01)


request_name("RequestName")
process = subprocess.Popen([sys.argv[1], sys.argv[2]], stdout=subprocess.PIPE, text=True)
try:
    pump_until(lambda: bool(select.select([process.stdout], [], [], 0)[0]))
    name = process.stdout.readline().strip()
    assert name.startswith(":"), name

    def call(path, interface, method, args=None):
        return bus.call_sync(name, path, interface, method, args, None,
                             Gio.DBusCallFlags.NONE, 2000, None).unpack()

    def property_value(key):
        return call("/StatusNotifierItem", "org.freedesktop.DBus.Properties", "Get",
                    xml("(ss)", ("org.kde.StatusNotifierItem", key)))[0]

    assert registrations and registrations[0] == (name, "/StatusNotifierItem")
    assert property_value("ItemIsMenu") is False
    assert property_value("Menu") == "/StatusNotifierItem/Menu"
    assert property_value("IconName") == os.path.splitext(os.path.basename(sys.argv[2]))[0]
    assert property_value("Status") == "Active"
    for _ in range(2):
        call("/StatusNotifierItem", "org.kde.StatusNotifierItem", "Activate", xml("(ii)", (0, 0)))
    assert call("/Test", "me.tawaq.TrayTest", "Counts") == (2, 0)

    def layout():
        return call("/StatusNotifierItem/Menu", "com.canonical.dbusmenu", "GetLayout",
                    xml("(iias)", (0, -1, [])))[1]

    row = layout()[2][0]
    assert row[1]["label"] == "Show Tawaq"
    call("/StatusNotifierItem/Menu", "com.canonical.dbusmenu", "Event",
         xml("(isvu)", (row[0], "clicked", xml("i", 0), 0)))
    assert call("/Test", "me.tawaq.TrayTest", "Counts") == (2, 1)
    call("/Test", "me.tawaq.TrayTest", "Update")
    assert property_value("Title") == "Next prayer · updated"
    assert property_value("ToolTip")[2] == "Next prayer · updated"
    assert layout()[2][0][1]["label"] == "Hide Tawaq"

    # A restarted panel must receive the existing item without creating another.
    while context.pending():
        context.iteration(False)
    before = len(registrations)
    request_name("ReleaseName")
    time.sleep(0.1)
    request_name("RequestName")
    pump_until(lambda: len(registrations) > before)
    assert registrations[-1] == (name, "/StatusNotifierItem")
    call("/Test", "me.tawaq.TrayTest", "Destroy")
    try:
        property_value("Title")
        raise AssertionError("Destroyed tray remained exported")
    except GLib.Error:
        pass
    call("/Test", "me.tawaq.TrayTest", "Quit")
    assert process.wait(timeout=5) == 0
    print("Native tray contract passed: activation, menu selection/update, host restart, cleanup")
finally:
    if process.poll() is None:
        process.terminate()
        process.wait(timeout=5)
