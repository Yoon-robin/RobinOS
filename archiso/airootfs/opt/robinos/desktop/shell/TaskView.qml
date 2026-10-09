import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Win+Tab like Windows' task view: every window with its picture, grouped by
// workspace (the one on screen first), minimized ones last. A click or Enter goes
// to the window, "새 작업 공간" to the first empty workspace, Esc closes.
PanelWindow {
    id: root

    readonly property bool open: ShellState.taskViewOpen
    property bool mapped: false
    // [{ title, windows: [HyprlandToplevel] }], built when the view opens
    property var groups: []
    // Every window in the order shown, for the arrow keys
    property var flat: []
    property int selected: 0

    screen: ShellState.overlayScreen ?? Quickshell.screens[0]
    visible: mapped
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "robinos-taskview"
    // Only while open: during the fade-out the keyboard already goes back, so a window
    // started from here (a terminal, an app) gets the focus (boot test, 2026-10-10)
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            build();
            mapped = true;
            Qt.callLater(() => content.forceActiveFocus());
        } else {
            mapped = false;
            groups = [];
            flat = [];
        }
    }

    function build() {
        const current = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
        const byWorkspace = {};
        const minimized = [];
        for (const win of ShellState.toArray(ShellState.windows)) {
            const ws = win.workspace;
            if (!ws)
                continue;
            if (ShellState.isMinimized(win))
                minimized.push(win);
            else if (ws.id > 0)
                (byWorkspace[ws.id] = byWorkspace[ws.id] ?? []).push(win);
        }
        const ids = Object.keys(byWorkspace).map(Number)
            .sort((a, b) => (b === current) - (a === current) || a - b);
        const out = ids.map(id => ({
                    title: "작업 공간 " + id + (id === current ? " · 지금 화면" : ""),
                    windows: byWorkspace[id].sort((a, b) => ShellState.switcherRank(a) - ShellState.switcherRank(b))
                }));
        if (minimized.length > 0)
            out.push({ title: "최소화한 창", windows: minimized });
        groups = out;
        flat = out.reduce((all, g) => all.concat(g.windows), []);
        selected = 0;
    }

    function close() {
        ShellState.taskViewOpen = false;
    }

    function go(win) {
        close();
        if (win)
            ShellState.switchTo(win);
    }

    function newWorkspace() {
        close();
        ShellState.newWorkspace();
    }

    // Dim the desktop; a click on it closes
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Theme.dark ? 0.55 : 0.35)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: Theme.barHeight + 24
        anchors.bottomMargin: 24
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: content

            width: Math.min(parent.width - 96, 1160)
            x: (parent.width - width) / 2
            spacing: 18
            focus: true

            Keys.onEscapePressed: root.close()
            Keys.onReturnPressed: root.go(root.flat[root.selected])
            Keys.onEnterPressed: root.go(root.flat[root.selected])
            Keys.onPressed: event => {
                const step = { [Qt.Key_Right]: 1, [Qt.Key_Tab]: 1, [Qt.Key_Left]: -1, [Qt.Key_Backtab]: -1 }[event.key];
                if (step !== undefined && root.flat.length > 0) {
                    root.selected = (root.selected + step + root.flat.length) % root.flat.length;
                    event.accepted = true;
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "작업 보기"
                    color: "white"
                    font.family: Theme.font
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                ActionButton {
                    text: "새 작업 공간"
                    onClicked: root.newWorkspace()
                }
            }

            Text {
                visible: root.flat.length === 0
                text: "열린 창이 없어요."
                color: "white"
                opacity: 0.8
                font.family: Theme.font
                font.pixelSize: 14
            }

            Repeater {
                model: root.groups

                ColumnLayout {
                    id: group

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: group.modelData.title
                        color: "white"
                        opacity: 0.85
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: tiles.implicitHeight + 24
                        radius: Theme.radiusLg
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border

                        layer.enabled: !Theme.lowPower
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Theme.shadow
                            shadowBlur: 0.8
                            shadowVerticalOffset: 8
                        }

                        Flow {
                            id: tiles

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 12

                            Repeater {
                                model: group.modelData.windows

                                WindowTile {
                                    required property var modelData

                                    win: modelData
                                    chosen: root.flat[root.selected] === modelData
                                    onPicked: root.go(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
