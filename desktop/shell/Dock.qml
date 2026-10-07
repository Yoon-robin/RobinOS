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

    readonly property var pinned: [
        { icon: "terminal", label: "터미널", appIds: ["foot", "footclient", "robinos-float"], command: ["foot"] },
        { icon: "folder", label: "파일", appIds: ["org.gnome.Nautilus"], command: ["nautilus", "--new-window"] },
        { icon: "globe", label: "브라우저", appIds: ["firefox"], command: ["firefox"] },
        { icon: "network", label: "Wireshark", appIds: ["org.wireshark.Wireshark", "wireshark"], command: ["wireshark"] }
    ]

    readonly property var toplevels: ToplevelManager.toplevels.values

    function windowsFor(appIds) {
        const out = [];
        for (let i = 0; i < toplevels.length; i++) {
            if (appIds.indexOf(toplevels[i].appId) !== -1)
                out.push(toplevels[i]);
        }
        return out;
    }

    function isPinned(appId) {
        for (let i = 0; i < pinned.length; i++) {
            if (pinned[i].appIds.indexOf(appId) !== -1)
                return true;
        }
        return false;
    }

    readonly property var extras: {
        const seen = {};
        const out = [];
        for (let i = 0; i < toplevels.length; i++) {
            const appId = toplevels[i].appId;
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

    // Focus the app's window (cycling through several), or start it.
    function activateOrLaunch(appIds, command) {
        const wins = windowsFor(appIds);
        if (wins.length === 0) {
            if (command)
                Quickshell.execDetached(command);
            return;
        }
        let current = -1;
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].activated)
                current = i;
        }
        wins[(current + 1) % wins.length].activate();
    }

    function isFocused(appIds) {
        const wins = windowsFor(appIds);
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].activated)
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
                    onClicked: dock.activateOrLaunch(modelData.appIds, modelData.command)
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
