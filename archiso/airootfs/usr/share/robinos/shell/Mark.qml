import QtQuick

// RobinOS mark for small places (bar, launcher, installer): the white robin glyph
// (assets/robinos-glyph.svg, from assets/brand) on the accent color.
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

    Image {
        anchors.centerIn: parent
        width: root.size * 0.78
        height: width
        source: Qt.resolvedUrl("assets/robinos-glyph.svg")
        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        smooth: true
    }
}
