import QtQuick
import "keys.js" as Keyboard

// robin-ui icon button: bare (rk-btn--bare) or outline (the control face in its line). Tab reaches it; Enter or Space presses it.
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
    color: active ? Theme.chosen : outline ? (mouse.containsMouse ? Theme.secondaryHover : Theme.secondary)
                                  : mouse.containsMouse ? Theme.hover : "transparent"
    border.width: outline ? 1 : 0
    border.color: mouse.containsMouse ? Theme.controlLineHover : Theme.borderStrong

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
