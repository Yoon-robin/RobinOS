import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// One window with its picture, icon and title: Alt+Tab (AltTab.qml) and the task
// view (TaskView.qml). The picture is taken once when the tile appears; minimized
// windows and windows without a first frame show their app's icon instead.
Rectangle {
    id: root

    // A HyprlandToplevel
    required property var win
    property bool chosen: false

    signal picked()

    readonly property string appId: win ? ShellState.appIdOf(win) : ""
    readonly property var entry: appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    readonly property string title: win ? (win.title || entry?.name || appId) : ""
    readonly property string iconSource: Quickshell.iconPath(entry?.icon ?? appId, "application-x-executable")

    implicitWidth: 208
    implicitHeight: 164
    radius: Theme.radiusMd
    color: chosen ? Theme.raised : mouse.containsMouse ? Theme.hover : "transparent"
    border.width: chosen ? 2 : 0
    border.color: Theme.primary

    Accessible.role: Accessible.Button
    Accessible.name: title

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScreencopyView {
                id: preview
                anchors.centerIn: parent
                captureSource: root.win?.wayland ?? null
                live: false
                constraintSize: Qt.size(parent.width, parent.height)
            }

            IconImage {
                visible: !preview.hasContent
                anchors.centerIn: parent
                implicitSize: 48
                source: root.iconSource
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconImage {
                implicitSize: 16
                source: root.iconSource
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: root.chosen ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
