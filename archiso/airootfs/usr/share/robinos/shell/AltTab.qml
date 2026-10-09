import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

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

    function title(win) {
        const entry = DesktopEntries.heuristicLookup(ShellState.appIdOf(win));
        return win.title || entry?.name || ShellState.appIdOf(win);
    }

    function icon(win) {
        const appId = ShellState.appIdOf(win);
        const entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry?.icon ?? appId, "application-x-executable");
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

                Rectangle {
                    id: tile

                    required property var modelData
                    required property int index
                    readonly property bool chosen: index === root.selected

                    width: card.tileWidth
                    height: card.tileHeight
                    radius: Theme.radiusMd
                    color: chosen ? Theme.raised : tileMouse.containsMouse ? Theme.hover : "transparent"
                    border.width: chosen ? 2 : 0
                    border.color: Theme.primary

                    Accessible.role: Accessible.Button
                    Accessible.name: root.title(modelData)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        // The window as it looks now; its icon when there is no picture
                        // (minimized windows, or before the first frame comes in)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ScreencopyView {
                                id: preview
                                anchors.centerIn: parent
                                captureSource: tile.modelData.wayland ?? null
                                live: false
                                constraintSize: Qt.size(parent.width, parent.height)
                            }

                            IconImage {
                                visible: !preview.hasContent
                                anchors.centerIn: parent
                                implicitSize: 48
                                source: root.icon(tile.modelData)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            IconImage {
                                implicitSize: 16
                                source: root.icon(tile.modelData)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.title(tile.modelData)
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: tile.chosen ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.selected = tile.index;
                            root.finish();
                        }
                    }
                }
            }
        }
    }
}
