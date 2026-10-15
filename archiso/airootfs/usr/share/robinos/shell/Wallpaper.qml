import QtQuick
import Quickshell
import Quickshell.Wayland

// RobinOS wallpaper: zinc background, soft lights in the brand colours (Robin red,
// orange, a little violet) and a faint dot grid. The lights give the glass panels
// (Theme.glass, T-152) a colour to show through. Drawn in QML so it follows the
// theme and fits any resolution.
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
                [0.78, 0.12, 0.62, "229,72,77", 0.26, 0.18],
                [0.12, 0.92, 0.58, "255,138,61", 0.18, 0.15],
                [0.42, 1.08, 0.55, "150,70,255", 0.12, 0.09]
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
            ctx.fillStyle = Theme.dark ? "rgba(255,255,255,0.07)" : "rgba(0,0,0,0.08)";
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
