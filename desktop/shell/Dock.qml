import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Floating dock: launcher, pinned apps, other running apps, trash.
PanelWindow {
    id: dock

    required property var modelData

    screen: modelData
    anchors.bottom: true
    margins.bottom: 10
    implicitWidth: Math.max(body.implicitWidth, 320)
    implicitHeight: body.implicitHeight + 40
    exclusiveZone: body.implicitHeight
    color: "transparent"
    // Only the dock body takes input; the tooltip strip above it is click-through.
    mask: Region {
        item: body
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "robinos-dock"

    // Windows the shell itself opens (the installer) carry Quickshell's app id
    readonly property var shellAppIds: ["org.quickshell", "quickshell"]

    // In the live session the installer comes first; it opens through the shell.
    // An app with a desktopId is pinned only once it is installed: Wireshark comes
    // with the network profile (robinctl profile network), like the launcher's lab list.
    readonly property var pinned: {
        DesktopEntries.applications.values; // re-evaluate after the background scan
        return (ShellState.isLive ? [
            { key: "installer", icon: "download", label: "RobinOS 설치", appIds: shellAppIds, command: null }
        ] : []).concat([
            { icon: "terminal", label: "터미널", appIds: ["foot", "footclient", "robinos-float"], command: ["foot"] },
            { icon: "folder", label: "파일", appIds: ["org.gnome.Nautilus"], command: ["nautilus", "--new-window"] },
            { icon: "globe", label: "브라우저", appIds: ["firefox"], command: ["firefox"] },
            { icon: "network", label: "Wireshark", appIds: ["org.wireshark.Wireshark", "wireshark"], command: ["wireshark"], desktopId: "org.wireshark.Wireshark" }
        ]).filter(app => !app.desktopId || !!DesktopEntries.byId(app.desktopId));
    }

    // Minimized windows are still in this list, so they keep their "running" dot
    function windowsFor(appIds) {
        return ShellState.windowsOf(appIds);
    }

    function isPinned(appId) {
        for (let i = 0; i < pinned.length; i++) {
            if (pinned[i].appIds.indexOf(appId) !== -1)
                return true;
        }
        return false;
    }

    readonly property var extras: {
        DesktopEntries.applications.values; // re-evaluate after the background scan
        const seen = {};
        const out = [];
        const windows = ShellState.windows;
        for (let i = 0; i < windows.length; i++) {
            const appId = ShellState.appIdOf(windows[i]);
            if (appId === "" || isPinned(appId) || seen[appId])
                continue;
            seen[appId] = true;
            const entry = DesktopEntries.heuristicLookup(appId);
            out.push({
                appId: appId,
                label: entry?.name ?? appId,
                icon: Quickshell.iconPath(entry?.icon ?? appId, "application-x-executable")
            });
        }
        return out;
    }

    // Open, bring to front, minimize or restore, like the Windows taskbar
    function activateOrLaunch(appIds, command) {
        ShellState.toggleApp(appIds, command);
    }

    function isFocused(appIds) {
        const wins = windowsFor(appIds);
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].activated && !ShellState.isMinimized(wins[i]))
                return true;
        }
        return false;
    }

    property string tipText: ""
    property real tipX: 0

    function showTip(item, text) {
        if (text === "") {
            tipText = "";
            return;
        }
        tipX = item.mapToItem(dock.contentItem, item.width / 2, 0).x;
        tipText = text;
    }

    Rectangle {
        visible: dock.tipText !== ""
        anchors.bottom: body.top
        anchors.bottomMargin: 8
        x: Math.max(0, Math.min(dock.width - width, dock.tipX - width / 2))
        width: tip.implicitWidth + 16
        height: 24
        radius: Theme.radiusSm
        color: Theme.primary

        Text {
            id: tip
            anchors.centerIn: parent
            text: dock.tipText
            color: Theme.primaryFg
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Rectangle {
        id: body

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: row.implicitWidth + 16
        implicitHeight: 60
        width: implicitWidth
        height: implicitHeight
        radius: Theme.radiusDock
        color: Theme.dockBg
        border.width: 1
        border.color: Theme.border

        Behavior on color {
            ColorAnimation { duration: Theme.dur }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            DockItem {
                id: launcherItem
                icon: "grid"
                label: "앱 런처"
                active: ShellState.launcherOpen
                onClicked: ShellState.toggleLauncher()
                onHoveredChanged: dock.showTip(launcherItem, hovered ? label : "")
            }

            Rectangle {
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                implicitWidth: 1
                implicitHeight: 28
                color: Theme.border
            }

            Repeater {
                model: dock.pinned

                DockItem {
                    id: pinnedItem

                    required property var modelData

                    icon: modelData.icon
                    label: modelData.label
                    running: dock.windowsFor(modelData.appIds).length > 0
                    focused: dock.isFocused(modelData.appIds)
                    onClicked: {
                        if (modelData.key === "installer" && dock.windowsFor(modelData.appIds).length === 0)
                            ShellState.openInstaller();
                        else
                            dock.activateOrLaunch(modelData.appIds, modelData.command);
                    }
                    onHoveredChanged: dock.showTip(pinnedItem, hovered ? label : "")
                }
            }

            Repeater {
                model: dock.extras

                DockItem {
                    id: extraItem

                    required property var modelData

                    appIcon: modelData.icon
                    label: modelData.label
                    running: true
                    focused: dock.isFocused([modelData.appId])
                    onClicked: dock.activateOrLaunch([modelData.appId], null)
                    onHoveredChanged: dock.showTip(extraItem, hovered ? label : "")
                }
            }

            Rectangle {
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                implicitWidth: 1
                implicitHeight: 28
                color: Theme.border
            }

            DockItem {
                id: trashItem
                icon: "trash"
                label: "휴지통"
                muted: true
                onClicked: Quickshell.execDetached(["nautilus", "trash:///"])
                onHoveredChanged: dock.showTip(trashItem, hovered ? label : "")
            }
        }
    }
}
