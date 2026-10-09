import QtQuick
import Quickshell
import Quickshell.Wayland

// A short menu like Windows' context menus in its own layer, shared by Win+X
// (QuickLinks.qml), the desktop's right click (DesktopMenu.qml) and the dock's
// (DockMenu.qml). The card (MenuCard.qml) goes with its corner at `at`, below it,
// or above it when `upward` (or when it wouldn't fit below), kept on screen.
PanelWindow {
    id: root

    property bool open: false
    property var items: []
    property point at: Qt.point(0, 0)
    property bool upward: false
    property string layerName: "robinos-menu"
    property bool mapped: false

    // Asks the owner to set `open` to false
    signal dismiss

    screen: ShellState.overlayScreen ?? Quickshell.screens[0]
    visible: mapped
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.layerName
    // Only while open: during the fade-out the keyboard already goes back, so a window
    // started from here (a terminal, an app) gets the focus (boot test, 2026-10-10)
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            card.selected = 0;
            mapped = true;
            Qt.callLater(() => card.forceActiveFocus());
        } else {
            mapped = false;
        }
    }

    // A click anywhere else closes it (either button, like Windows)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.dismiss()
    }

    MenuCard {
        id: card

        readonly property bool fitsBelow: root.at.y + height <= parent.height - 8

        x: Math.max(8, Math.min(parent.width - width - 8, root.at.x))
        y: Math.max(8, root.upward || !fitsBelow ? root.at.y - height : root.at.y)
        items: root.items
        focus: true

        onDismissed: root.dismiss()
        onPicked: item => {
            root.dismiss();
            // After the menu lets go of the keyboard, so a new window gets the focus
            Qt.callLater(item.run);
        }
    }
}
