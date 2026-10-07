import QtQuick
import "keys.js" as Keyboard

// shadcn "ghost" / "outline" icon button. Tab reaches it; Enter or Space presses it.
Rectangle {
    id: root

    property string icon
    property string label
    property real iconSize: 16
    property bool outline: false
    property bool active: false
    property color iconColor: Theme.fgSoft

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.radiusSm
    color: active ? Theme.secondary : mouse.containsMouse ? Theme.hover : "transparent"
    border.width: outline ? 1 : 0
    border.color: Theme.border

    Accessible.role: Accessible.Button
    Accessible.name: label

    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (Keyboard.activates(event)) {
            root.clicked();
            event.accepted = true;
        }
    }

    FocusRing {
        baseRadius: root.radius
    }

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.iconColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
