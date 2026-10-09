import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "keys.js" as Keyboard

// A short menu like Windows' context menus, shared by Win+X (QuickLinks.qml) and the
// desktop's right click (DesktopMenu.qml). items: [{ icon, title, hint, run }] or
// { separator: true }. The card's corner goes at `at`, below it, or above it when
// `upward` (or when it wouldn't fit below), kept on screen.
PanelWindow {
    id: root

    property bool open: false
    property var items: []
    property point at: Qt.point(0, 0)
    property bool upward: false
    property string layerName: "robinos-menu"
    property int selected: 0
    property bool mapped: false
    readonly property var choices: items.filter(item => !item.separator)

    // Asks the owner to set `open` to false
    signal dismiss

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
    WlrLayershell.namespace: root.layerName
    // Only while open: during the fade-out the keyboard already goes back, so a window
    // started from here (a terminal, an app) gets the focus (boot test, 2026-10-10)
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            selected = 0;
            mapped = true;
            Qt.callLater(() => card.forceActiveFocus());
        } else {
            mapped = false;
        }
    }

    function pick(item) {
        dismiss();
        // After the menu lets go of the keyboard, so a new window gets the focus
        Qt.callLater(item.run);
    }

    // A click anywhere else closes it (either button, like Windows)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.dismiss()
    }

    Rectangle {
        id: card

        readonly property bool fitsBelow: root.at.y + height <= parent.height - 8

        x: Math.max(8, Math.min(parent.width - width - 8, root.at.x))
        y: Math.max(8, root.upward || !fitsBelow ? root.at.y - height : root.at.y)
        width: 260
        height: list.implicitHeight + 12
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        focus: true

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        Keys.onEscapePressed: root.dismiss()
        Keys.onPressed: event => {
            const step = { [Qt.Key_Down]: 1, [Qt.Key_Tab]: 1, [Qt.Key_Up]: -1, [Qt.Key_Backtab]: -1 }[event.key];
            if (step !== undefined) {
                root.selected = (root.selected + step + root.choices.length) % root.choices.length;
                event.accepted = true;
            } else if (Keyboard.activates(event)) {
                root.pick(root.choices[root.selected]);
                event.accepted = true;
            }
        }

        // Keep clicks between the rows from closing it
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        ColumnLayout {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 0

            // By index: the entries keep their functions, which a model copy would drop
            Repeater {
                model: root.items.length

                Item {
                    id: entry

                    required property int index
                    readonly property var modelData: root.items[index]
                    readonly property int choice: root.choices.indexOf(modelData)
                    readonly property bool chosen: choice === root.selected

                    Layout.fillWidth: true
                    implicitHeight: modelData.separator ? 9 : 34

                    Rectangle {
                        visible: entry.modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: Theme.border
                    }

                    Rectangle {
                        visible: entry.modelData.separator !== true
                        anchors.fill: parent
                        radius: Theme.radiusMd
                        color: entry.chosen || rowMouse.containsMouse ? Theme.hover : "transparent"

                        Accessible.role: Accessible.MenuItem
                        Accessible.name: entry.modelData.title ?? ""

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Icon {
                                name: entry.modelData.icon ?? ""
                                size: 15
                                color: Theme.fgSoft
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entry.modelData.title ?? ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Text {
                                text: entry.modelData.hint ?? ""
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selected = entry.choice
                            onClicked: root.pick(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
