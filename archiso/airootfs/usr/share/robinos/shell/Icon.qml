import QtQuick
import QtQuick.Shapes
import "icons.js" as Icons

// Lucide stroke icon drawn as a vector Shape, so it takes any color at any size.
Item {
    id: root

    property string name
    property real size: 16
    property color color: Theme.fg
    property real stroke: 2

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: Icons.path(root.name)
            }
        }
    }
}
