#!/usr/bin/env bash
# A tray icon (StatusNotifierItem) for the boot test, shown in the bar's tray.
#
# The live ISO has no app with a tray icon of its own (the shell hides fcitx5's),
# so boot-test-qmp.py runs this from /opt/robinos/scripts. A click on the icon
# calls Activate, which this writes to /tmp/sni-activated.
set -euo pipefail

exec python3 - <<'EOF'
import os

from gi.repository import Gio, GLib

XML = """<node><interface name="org.kde.StatusNotifierItem">
<property name="Id" type="s" access="read"/><property name="Title" type="s" access="read"/>
<property name="Status" type="s" access="read"/><property name="Category" type="s" access="read"/>
<property name="IconName" type="s" access="read"/>
<method name="Activate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
</interface></node>"""
PROPS = {"Id": "robinos-tray-test", "Title": "트레이 테스트", "Status": "Active",
         "Category": "ApplicationStatus", "IconName": "utilities-terminal"}


def get_property(conn, sender, path, iface, name):
    return GLib.Variant("s", PROPS[name])


def call(conn, sender, path, iface, method, params, invocation):
    with open("/tmp/sni-activated", "w") as f:
        f.write(method + "\n")
    invocation.return_value(None)


bus = Gio.bus_get_sync(Gio.BusType.SESSION)
bus.register_object("/StatusNotifierItem", Gio.DBusNodeInfo.new_for_xml(XML).interfaces[0],
                    call, get_property, None)
name = f"org.kde.StatusNotifierItem-{os.getpid()}-1"
Gio.bus_own_name_on_connection(bus, name, Gio.BusNameOwnerFlags.NONE, None, None)
bus.call_sync("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher",
              "RegisterStatusNotifierItem", GLib.Variant("(s)", (name,)), None,
              Gio.DBusCallFlags.NONE, -1, None)
GLib.MainLoop().run()
EOF
