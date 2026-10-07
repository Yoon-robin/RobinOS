import QtQuick

// shadcn-style slider: thin track, primary range, hollow round thumb. value is 0..1.
// Tab reaches it; arrow keys move it by 5%, Home and End to the ends.
Item {
    id: root

    property real value: 0
    property string label
    property bool dragging: dragArea.pressed
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : value

    signal moved(real value)

    implicitHeight: 20

    Accessible.role: Accessible.Slider
    Accessible.name: label

    activeFocusOnTab: true
    Keys.onPressed: event => {
        const steps = { [Qt.Key_Right]: 0.05, [Qt.Key_Up]: 0.05, [Qt.Key_Left]: -0.05, [Qt.Key_Down]: -0.05 };
        if (event.key in steps)
            moved(Math.max(0, Math.min(1, value + steps[event.key])));
        else if (event.key === Qt.Key_Home)
            moved(0);
        else if (event.key === Qt.Key_End)
            moved(1);
        else
            return;
        event.accepted = true;
    }

    function setFromX(x) {
        dragValue = Math.max(0, Math.min(1, (x - thumb.width / 2) / (width - thumb.width)));
        moved(dragValue);
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.secondary

        Rectangle {
            width: thumb.x + thumb.width / 2
            height: parent.height
            radius: 3
            color: Theme.primary
        }
    }

    Rectangle {
        id: thumb
        anchors.verticalCenter: parent.verticalCenter
        x: root.shown * (root.width - width)
        width: 16
        height: 16
        radius: 8
        color: Theme.bg
        border.width: 1.5
        border.color: Theme.primary

        // The thumb shows the slider's keyboard focus
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.ring
            visible: root.activeFocus
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromX(mouse.x);
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
