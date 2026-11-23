import QtQuick
import "keys.js" as Keyboard

// robin-ui switch (rk-switch), 34x19: off is a dark groove with a 1px line and a grey
// knob, on is blue with a white knob. Tab reaches it; Enter or Space flips it.
Rectangle {
    id: root

    property bool checked: false
    property string label

    signal toggled()

    implicitWidth: 34
    implicitHeight: 19
    radius: 10
    color: checked ? Theme.accent : Theme.switchOff
    border.width: checked ? 0 : 1
    border.color: Theme.borderStrong
    opacity: enabled ? 1 : 0.45

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
        ColorAnimation { duration: 165 }
    }

    FocusRing {
        baseRadius: root.radius
    }

    Rectangle {
        y: 2.5
        x: root.checked ? 17.5 : 2.5
        width: 14
        height: 14
        radius: 7
        color: root.checked ? "#ffffff" : Theme.switchKnob

        Behavior on x {
            NumberAnimation { duration: 165; easing.type: Easing.OutCubic }
        }
    }

    // A larger hit area than the 19px groove
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
