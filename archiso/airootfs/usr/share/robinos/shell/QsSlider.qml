import QtQuick

// shadcn-style slider: thin track, primary range, hollow round thumb. value is 0..1.
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
