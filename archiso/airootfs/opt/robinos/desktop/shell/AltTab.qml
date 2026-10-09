import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// Alt+Tab like Windows: while Alt is held, this workspace's windows (the last used
// first, minimized ones too) with a picture of each. Tab moves on, Shift+Tab back,
// letting go of Alt switches. robinos.lua sends robinos:alttab, alttab-back and
// alttab-done (Alt released); the overlay never takes the keyboard.
PanelWindow {
    id: root

    property bool open: false
    // HyprlandToplevel objects, from ShellState.switcherWindows()
    property var items: []
    property int selected: 0

    screen: ShellState.focusedScreen
    visible: open
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "robinos-alttab"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function step(delta) {
        if (!open) {
            const list = ShellState.switcherWindows();
            if (list.length === 0)
                return;
            items = list;
            // The first Tab goes to the window used before this one
            selected = list.length > 1 ? (delta > 0 ? 1 : list.length - 1) : 0;
            open = true;
        } else if (items.length > 0) {
            selected = (selected + delta + items.length) % items.length;
        }
    }

    // A window closed while the list is up drops out of it
    Connections {
        target: ShellState

        function onWindowsChanged() {
            if (!root.open)
                return;
            const alive = root.items.filter(w => w && ShellState.toArray(ShellState.windows).indexOf(w) !== -1);
            if (alive.length === root.items.length)
                return;
            if (alive.length === 0) {
                root.cancel();
                return;
            }
            root.selected = Math.min(root.selected, alive.length - 1);
            root.items = alive;
        }
    }

    function finish() {
        if (!open)
            return;
        const win = items[selected];
        open = false;
        items = [];
        if (win)
            ShellState.switchTo(win);
    }

    function cancel() {
        open = false;
        items = [];
    }

    // A click outside the card closes without switching
    MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
    }

    Rectangle {
        id: card

        readonly property int tileWidth: 208
        readonly property int tileHeight: 164
        readonly property int perRow: Math.max(1, Math.min(root.items.length, Math.floor((root.width - 112) / (tileWidth + 12))))

        anchors.centerIn: parent
        width: perRow * (tileWidth + 12) - 12 + 32
        height: tiles.implicitHeight + 32
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        // Keep clicks between the tiles from closing it
        MouseArea {
            anchors.fill: parent
        }

        Flow {
            id: tiles

            anchors.centerIn: parent
            width: card.width - 32
            spacing: 12

            Repeater {
                model: root.items

                WindowTile {
                    required property var modelData
                    required property int index

                    win: modelData
                    chosen: index === root.selected
                    onPicked: {
                        root.selected = index;
                        root.finish();
                    }
                }
            }
        }
    }
}
