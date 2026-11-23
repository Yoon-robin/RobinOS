import QtQuick
import Quickshell
import Quickshell.Wayland

// RobinOS wallpaper (robin-ui V5): the blue-black page, one faint glow of the
// one blue (like the brand mark's) and a faint dot grid. No other colours, no
// glass to show through. Drawn in QML so it follows the theme and fits any resolution.
PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "robinos-wallpaper"

    Canvas {
        id: canvas

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: Theme

            function onDarkChanged() {
                canvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();

            // [x, y, radius] as parts of the screen, and the colour in dark / light
            const size = Math.max(w, h);
            const lights = [
                [0.80, 0.08, 0.70, "75,125,254", 0.14, 0.08]
            ];
            for (const [lx, ly, lr, rgb, darkAlpha, lightAlpha] of lights) {
                const g = ctx.createRadialGradient(w * lx, h * ly, 0, w * lx, h * ly, size * lr);
                g.addColorStop(0, "rgba(" + rgb + "," + (Theme.dark ? darkAlpha : lightAlpha) + ")");
                g.addColorStop(0.55, "rgba(" + rgb + "," + (Theme.dark ? darkAlpha : lightAlpha) * 0.3 + ")");
                g.addColorStop(1, "rgba(" + rgb + ",0)");
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, w, h);
            }

            const step = 22;
            const r = 1;
            ctx.fillStyle = Theme.dark ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.06)";
            ctx.beginPath();
            for (let y = step / 2; y < h; y += step) {
                for (let x = step / 2; x < w; x += step) {
                    ctx.moveTo(x + r, y);
                    ctx.arc(x, y, r, 0, Math.PI * 2);
                }
            }
            ctx.fill();
        }
    }

    // A picture set with "배경으로 설정" (ShellState.wallpaperPath) covers the
    // drawn wallpaper once it has loaded; a missing file leaves the drawn one
    Image {
        anchors.fill: parent
        source: ShellState.wallpaperPath !== "" ? "file://" + ShellState.wallpaperPath + "?v=" + ShellState.wallpaperVersion : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width, root.height)
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.dur }
        }
    }

    // A right click on the desktop opens its menu (DesktopMenu.qml), like Windows
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => ShellState.openDesktopMenu(root.screen, mouse.x, mouse.y)
    }
}
