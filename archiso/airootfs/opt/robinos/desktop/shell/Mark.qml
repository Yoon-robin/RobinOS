import QtQuick
import QtQuick.Effects

// RobinOS mark for small places (bar, launcher, settings, installer), the robin-ui
// mark (rk-mark): the white robin glyph (assets/robinos-glyph.svg, from assets/brand)
// on the kit's near-black tile, with a glow of the one blue. Without a GPU the glow
// is left out.
Rectangle {
    id: root

    property real size: 18

    implicitWidth: size
    implicitHeight: size
    radius: Math.max(4, Math.round(size * 0.23))
    color: Theme.markBg

    Image {
        anchors.centerIn: parent
        width: root.size * 0.74
        height: width
        source: Qt.resolvedUrl("assets/robinos-glyph.svg")
        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        smooth: true

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(75 / 255, 125 / 255, 254 / 255, 0.9)
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
    }
}
