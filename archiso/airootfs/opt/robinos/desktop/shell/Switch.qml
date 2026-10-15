import QtQuick
import "keys.js" as Keyboard

// shadcn switch: the track is primary when on. Tab reaches it; Enter or Space flips it.
Rectangle {
    id: root

    property bool checked: false
    property string label

    signal toggled()

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.primary : Theme.input
    opacity: enabled ? 1 : 0.5

    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked

    activeFocusOnTab: enabled
    Keys.onPressed: event => {
        if (Keyboard.activates(event)) {
            root.toggled();
            event.accepted = true;
        }
    }

    Behavior on color {
        ColorAnimation { duration: Theme.durFast }
    }

    FocusRing {
        baseRadius: root.radius
    }

    Rectangle {
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        width: root.height - 4
        height: width
        radius: width / 2
        color: Theme.bg

        Behavior on x {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
