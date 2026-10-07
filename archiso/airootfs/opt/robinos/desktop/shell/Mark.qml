import QtQuick

// RobinOS logo mark: a terminal prompt on the accent color.
Rectangle {
    id: root

    property real size: 18

    implicitWidth: size
    implicitHeight: size
    radius: Math.round(size * 0.28)
    color: Theme.accent

    Behavior on color {
        ColorAnimation { duration: Theme.dur }
    }

    Icon {
        anchors.centerIn: parent
        name: "mark"
        size: root.size * 0.68
        stroke: 3
        color: "#ffffff"
    }
}
