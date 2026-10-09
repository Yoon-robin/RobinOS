import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "keys.js" as Keyboard

// The card of a short menu like Windows' context menus: rows with an icon, a title
// and a hint, arrows/Tab to move, Enter/Space to pick, Esc to close. Used in its own
// layer by PopupMenu.qml (Win+X, the desktop, the dock) and inside the launcher.
// items: [{ icon, title, hint, run }] or { separator: true }.
Rectangle {
    id: card

    property var items: []
    property int selected: 0
    readonly property var choices: items.filter(item => !item.separator)

    signal picked(var item)
    signal dismissed

    width: 260
    height: list.implicitHeight + 12
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

    Keys.onEscapePressed: card.dismissed()
    Keys.onPressed: event => {
        const step = { [Qt.Key_Down]: 1, [Qt.Key_Tab]: 1, [Qt.Key_Up]: -1, [Qt.Key_Backtab]: -1 }[event.key];
        if (step !== undefined) {
            card.selected = (card.selected + step + card.choices.length) % card.choices.length;
            event.accepted = true;
        } else if (Keyboard.activates(event)) {
            card.picked(card.choices[card.selected]);
            event.accepted = true;
        }
    }

    // Keep clicks between the rows from reaching what is under the card
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
            model: card.items.length

            Item {
                id: entry

                required property int index
                readonly property var modelData: card.items[index]
                readonly property int choice: card.choices.indexOf(modelData)
                readonly property bool chosen: choice === card.selected

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
                        onEntered: card.selected = entry.choice
                        onClicked: card.picked(entry.modelData)
                    }
                }
            }
        }
    }
}
