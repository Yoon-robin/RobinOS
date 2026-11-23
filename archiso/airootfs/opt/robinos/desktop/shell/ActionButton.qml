import QtQuick
import "keys.js" as Keyboard

// robin-ui button (rk-btn), 7px corners:
//   "default"     the blue fill: the one main action of a screen
//   "outline"     the plain control: control face in its 1px line
//   "ghost"       bare: no face until hovered, soft words
//   "danger"      what cannot be undone: a red line and red words
//   "danger-fill" filled red: only the one button of a confirm
// Tab reaches it; Enter or Space presses it.
Rectangle {
    id: root

    property string text
    property string variant: "default"
    readonly property bool primary: variant === "default"
    readonly property bool danger: variant === "danger" || variant === "danger-fill"
    readonly property bool filled: primary || variant === "danger-fill"
    readonly property bool hovered: mouse.containsMouse

    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 36
    radius: Theme.radiusMd
    color: {
        if (primary)
            return mouse.pressed ? Theme.primary : hovered ? Theme.primaryHover : Theme.primary;
        if (variant === "danger-fill")
            return Theme.destructiveSolid;
        if (variant === "danger")
            return hovered ? Theme.destructiveSoft : "transparent";
        if (variant === "ghost")
            return hovered ? Theme.hover : "transparent";
        return mouse.pressed ? Theme.controlPress : hovered ? Theme.secondaryHover : Theme.secondary;
    }
    border.width: filled || variant === "ghost" ? 0 : 1
    border.color: danger ? Theme.destructiveSolid : hovered ? Theme.controlLineHover : Theme.borderStrong
    opacity: enabled ? 1 : 0.45
    scale: mouse.pressed && enabled ? 0.98 : 1

    Accessible.role: Accessible.Button
    Accessible.name: text

    activeFocusOnTab: enabled
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

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.filled ? Theme.primaryFg
             : root.danger ? Theme.destructive
             : root.variant === "ghost" ? (root.hovered ? Theme.head : Theme.muted)
             : root.hovered ? Theme.head : Theme.fg
        font.family: Theme.font
        font.pixelSize: 14
        font.weight: Theme.weightStrong
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
