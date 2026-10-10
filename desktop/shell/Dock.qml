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
    // Room for the window previews (four pictures) all the time: resizing the surface
    // when they open made the pointer leave and enter again, which hid them, over and
    // over (boot test, 2026-10-10). Outside the mask the strip is click-through.
    implicitWidth: Math.max(body.implicitWidth, 760)
    implicitHeight: body.implicitHeight + 168
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

    // Where the launcher button starts on screen, for the Win+X menu above it
    Binding {
        target: ShellState
        property: "quickLinksX"
        value: (dock.screen.width - body.width) / 2 + 8
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
        dock.width; // read again when the dock or its body changes size
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

    // A right click on an app, like the Windows taskbar's jump list (DockMenu.qml):
    // a new window, pin or unpin, close its windows. Each action is optional.
    function openAppMenu(item, label, appIds, actions) {
        const wins = windowsFor(appIds);
        const items = [];
        if (actions.launch)
            items.push({ icon: "plus", title: "새 창 · " + label, run: actions.launch });
        if (actions.pin)
            items.push({ icon: "pin", title: "독에 고정", run: actions.pin });
        if (actions.unpin)
            items.push({ icon: "pin", title: "독에서 고정 풀기", run: actions.unpin });
        if (wins.length > 0) {
            if (items.length > 0)
                items.push({ separator: true });
            items.push({ icon: "x", title: wins.length > 1 ? "창 " + wins.length + "개 모두 닫기" : "창 닫기", run: () => ShellState.closeWindows(wins) });
        }
        if (items.length === 0)
            return;
        closePreview();
        showTip(item, "");
        // The body is centered on the screen, 10 px above its bottom edge
        const left = (dock.screen.width - body.width) / 2 + item.mapToItem(body, 0, 0).x;
        ShellState.openDockMenu(dock.screen, left, dock.screen.height - 10 - body.height - 8, items);
    }

    // A window closed while its picture shows: drop it. Its dock button may go away
    // with it, and then no "pointer left" ever comes, so the card closes here too
    // (a closed calculator's empty card stayed up in the boot test, 2026-10-10)
    Connections {
        target: ShellState

        function onWindowsChanged() {
            if (!dock.previewShown)
                return;
            const alive = dock.previewWins.filter(w => w && ShellState.toArray(ShellState.windows).indexOf(w) !== -1);
            if (alive.length !== dock.previewWins.length)
                dock.previewWins = alive;
        }
    }

    onPreviewItemChanged: {
        if (previewShown && !previewItem)
            closePreview();
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
                active: ShellState.launcherOpen || ShellState.quickLinksOpen
                onClicked: ShellState.toggleLauncher()
                // Like the Windows Start button: a right click opens the quick link menu (Win+X)
                onRightClicked: {
                    dock.showTip(launcherItem, "");
                    ShellState.toggleQuickLinks();
                }
                onHoveredChanged: dock.showTip(launcherItem, hovered ? label + " · 오른쪽 클릭: 빠른 메뉴" : "")
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
                    // RobinOS's own apps stay pinned; the installer runs once
                    // The values are taken now: a rescan of the desktop entries can
                    // make this button again while its menu is open
                    onRightClicked: {
                        const command = modelData.command;
                        dock.openAppMenu(pinnedItem, label, modelData.appIds, {
                            launch: modelData.key === "installer" ? null : () => Quickshell.execDetached(command)
                        });
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
                        const entry = modelData.entry;
                        const id = modelData.id;
                        const name = modelData.label;
                        dock.openAppMenu(userPinItem, label, modelData.appIds, {
                            launch: () => entry.execute(),
                            unpin: () => ShellState.unpinFromDock(id, name)
                        });
                    }
                    onHoveredChanged: {
                        dock.showTip(userPinItem, hovered ? label : "");
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
                    // Only apps with a desktop entry can start again or stay pinned
                    onRightClicked: {
                        const entry = DesktopEntries.heuristicLookup(modelData.appId);
                        dock.openAppMenu(extraItem, label, [modelData.appId], {
                            launch: entry ? () => entry.execute() : null,
                            pin: entry ? () => ShellState.pinToDock(entry.id, entry.name) : null
                        });
                    }
                    onHoveredChanged: {
                        dock.showTip(extraItem, hovered ? label : "");
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
