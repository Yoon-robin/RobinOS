import QtQuick
import QtQuick.Layouts
import "keys.js" as Keyboard

// Quick settings tile: the control face in its line; on is the blue's soft face with
// a blue icon (the blue fill is kept for a screen's one main action).
// With hasDetail, a chevron on the right opens more settings.
// Tab reaches the tile and its chevron; Enter or Space presses them.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool checked: false
    property bool hasDetail: false

    signal toggled()
    signal detailRequested()

    implicitHeight: 58
    radius: Theme.radiusTile
    color: checked ? Theme.accentSoft : mouse.containsMouse ? Theme.tileHover : Theme.tile
    border.width: 1
    border.color: checked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                          : mouse.containsMouse ? Theme.controlLineHover : Theme.borderStrong
    opacity: enabled ? 1 : 0.5

    Accessible.role: Accessible.CheckBox
    Accessible.name: title
    Accessible.checked: checked

    activeFocusOnTab: enabled
    Keys.onPressed: event => {
        if (Keyboard.activates(event)) {
            root.toggled();
            event.accepted = true;
        }
    }

    FocusRing {
        baseRadius: root.radius
    }

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: root.hasDetail ? 4 : 12
        spacing: 10

        Icon {
            name: root.icon
            color: root.checked ? Theme.accent : Theme.muted
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.head
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Theme.weightStrong
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: detail

            visible: root.hasDetail
            Layout.preferredWidth: 26
            Layout.preferredHeight: 44
            radius: Theme.radiusSm
            color: detailMouse.containsMouse ? Theme.hover : "transparent"

            Accessible.role: Accessible.Button
            Accessible.name: root.title + " 설정"

            activeFocusOnTab: root.enabled
            Keys.onPressed: event => {
                if (Keyboard.activates(event)) {
                    root.detailRequested();
                    event.accepted = true;
                }
            }

            FocusRing {
                baseRadius: detail.radius
                anchors.margins: -1
            }

            Icon {
                anchors.centerIn: parent
                name: "chevron-right"
                size: 14
                color: Theme.muted
            }

            MouseArea {
                id: detailMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.detailRequested()
            }
        }
    }
}
