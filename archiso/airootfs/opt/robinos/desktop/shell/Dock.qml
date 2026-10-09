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
    implicitWidth: Math.max(body.implicitWidth, previewShown ? previewCard.width : 0, 320)
    implicitHeight: body.implicitHeight + (previewShown ? previewCard.height + 16 : 40)
    exclusiveZone: body.implicitHeight
    color: "transparent"
    // Only the dock body (and the window previews) take input; the tooltip strip
    // above it is click-through.
    mask: Region {
        item: body

        Region {
            item: dock.previewShown ? previewCard : null
        }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "robinos-dock"

    // Windows the shell itself opens, by the ids ShellState.appIdOf gives them
    readonly property var shellApps: ({
            "robinos-learn": { icon: "graduation-cap", label: "학습 센터" }
        })

    // In the live session the installer comes first; it opens through the shell.
    // An app with a desktopId is pinned only once it is installed: Wireshark comes
    // with the network profile (robinctl profile network), like the launcher's lab list.
    readonly property var pinned: {
        DesktopEntries.applications.values; // re-evaluate after the background scan
        return (ShellState.isLive ? [
            { key: "installer", icon: "download", label: "RobinOS 설치", appIds: ["robinos-installer"], command: null }
        ] : []).concat([
            { icon: "terminal", label: "터미널", appIds: ["foot", "footclient", "robinos-float"], command: ["foot"] },
            { icon: "folder", label: "파일", appIds: ["org.gnome.Nautilus"], command: ["nautilus", "--new-window"] },
            { icon: "globe", label: "브라우저", appIds: ["firefox"], command: ["firefox"] },
            { icon: "network", label: "Wireshark", appIds: ["org.wireshark.Wireshark", "wireshark"], command: ["wireshark"], desktopId: "org.wireshark.Wireshark" }
        ]).filter(app => !app.desktopId || !!DesktopEntries.byId(app.desktopId));
    }

    // Apps pinned with a right click (ShellState.dockPins), after the built-in ones
    readonly property var userPins: {
        DesktopEntries.applications.values; // re-evaluate after the background scan
        const out = [];
        for (const id of ShellState.dockPins) {
            const entry = DesktopEntries.byId(id);
            if (!entry)
                continue;
            out.push({
                id: id,
                entry: entry,
                label: entry.name,
                icon: Quickshell.iconPath(entry.icon, "application-x-executable"),
                // Windows report the desktop id or the StartupWMClass as their app id
                appIds: [id, id.toLowerCase(), entry.startupClass ?? ""].filter(appId => appId !== "")
            });
        }
        return out;
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
        for (let i = 0; i < userPins.length; i++) {
            if (userPins[i].appIds.indexOf(appId) !== -1)
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
            const shellApp = shellApps[appId];
            if (shellApp) {
                out.push({ appId: appId, label: shellApp.label, glyph: shellApp.icon, icon: "" });
                continue;
            }
            const entry = DesktopEntries.heuristicLookup(appId);
            out.push({
                appId: appId,
                label: entry?.name ?? appId,
                glyph: "",
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

    // ---- Window previews, like the Windows taskbar ----
    // Half a second on a running app shows its windows above the dock. The card is
    // part of this surface, so moving onto it keeps it open; a click on a picture
    // goes to that window.

    property var previewWins: []
    property Item previewItem: null
    property var pendingPreview: null
    readonly property bool previewShown: previewWins.length > 0
    readonly property real previewCenter: {
        dock.width; // read again when the dock grows for the card
        body.x;
        return previewItem ? previewItem.mapToItem(dock.contentItem, previewItem.width / 2, 0).x : dock.width / 2;
    }

    function hoverApp(item, appIds, hovered) {
        if (hovered) {
            hidePreview.stop();
            pendingPreview = { item: item, appIds: appIds };
            if (previewShown)
                openPreview();
            else
                showPreview.restart();
        } else {
            showPreview.stop();
            hidePreview.restart();
        }
    }

    function openPreview() {
        const wanted = pendingPreview;
        const wins = wanted ? windowsFor(wanted.appIds).slice(0, 4) : [];
        previewItem = wins.length > 0 ? wanted.item : null;
        previewWins = wins;
    }

    function closePreview() {
        showPreview.stop();
        hidePreview.stop();
        previewWins = [];
    }

    Timer {
        id: showPreview
        interval: 500
        onTriggered: dock.openPreview()
    }

    Timer {
        id: hidePreview
        interval: 300
        onTriggered: dock.previewWins = []
    }

    Rectangle {
        id: previewCard

        visible: dock.previewShown
        anchors.bottom: body.top
        anchors.bottomMargin: 8
        x: Math.max(0, Math.min(dock.width - width, dock.previewCenter - width / 2))
        width: previewRow.implicitWidth + 16
        height: previewRow.implicitHeight + 16
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        HoverHandler {
            onHoveredChanged: hovered ? hidePreview.stop() : hidePreview.restart()
        }

        Row {
            id: previewRow

            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: dock.previewWins

                WindowTile {
                    required property var modelData

                    win: modelData
                    width: 176
                    height: 136
                    onPicked: {
                        dock.closePreview();
                        ShellState.switchTo(modelData);
                    }
                }
            }
        }
    }

    Rectangle {
        visible: dock.tipText !== "" && !dock.previewShown
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
                        dock.closePreview();
                        if (modelData.key === "installer" && dock.windowsFor(modelData.appIds).length === 0)
                            ShellState.openInstaller();
                        else
                            dock.activateOrLaunch(modelData.appIds, modelData.command);
                    }
                    onHoveredChanged: {
                        dock.showTip(pinnedItem, hovered ? label : "");
                        dock.hoverApp(pinnedItem, modelData.appIds, hovered);
                    }
                }
            }

            Repeater {
                model: dock.userPins

                DockItem {
                    id: userPinItem

                    required property var modelData

                    appIcon: modelData.icon
                    label: modelData.label
                    running: dock.windowsFor(modelData.appIds).length > 0
                    focused: dock.isFocused(modelData.appIds)
                    onClicked: {
                        dock.closePreview();
                        if (dock.windowsFor(modelData.appIds).length === 0)
                            modelData.entry.execute();
                        else
                            dock.activateOrLaunch(modelData.appIds, null);
                    }
                    onRightClicked: {
                        // The tile under the pointer changes, and so would its tip
                        dock.showTip(userPinItem, "");
                        ShellState.unpinFromDock(modelData.id, modelData.label);
                    }
                    onHoveredChanged: {
                        dock.showTip(userPinItem, hovered ? label + " · 오른쪽 클릭: 고정 풀기" : "");
                        dock.hoverApp(userPinItem, modelData.appIds, hovered);
                    }
                }
            }

            Repeater {
                model: dock.extras

                DockItem {
                    id: extraItem

                    required property var modelData

                    icon: modelData.glyph
                    appIcon: modelData.icon
                    label: modelData.label
                    running: true
                    focused: dock.isFocused([modelData.appId])
                    onClicked: {
                        dock.closePreview();
                        dock.activateOrLaunch([modelData.appId], null);
                    }
                    // Only apps with a desktop entry can come back after closing
                    onRightClicked: {
                        const entry = DesktopEntries.heuristicLookup(modelData.appId);
                        if (entry) {
                            dock.showTip(extraItem, "");
                            ShellState.pinToDock(entry.id, entry.name);
                        }
                    }
                    onHoveredChanged: {
                        dock.showTip(extraItem, hovered ? label + " · 오른쪽 클릭: 독에 고정" : "");
                        dock.hoverApp(extraItem, [modelData.appId], hovered);
                    }
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
