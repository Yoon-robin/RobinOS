import QtQuick
import Quickshell
import Quickshell.Wayland

// RobinOS wallpaper: zinc background, a faint dot grid and a soft light from the top.
// Drawn in QML so it follows the theme and fits any resolution.
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

            const light = ctx.createRadialGradient(w / 2, 0, 0, w / 2, 0, Math.max(w, h) * 0.6);
            light.addColorStop(0, Theme.dark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.035)");
            light.addColorStop(1, "rgba(0,0,0,0)");
            ctx.fillStyle = light;
            ctx.fillRect(0, 0, w, h);

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
