import QtQuick

// A dock app's right-click menu, like the Windows taskbar's jump list: a new window,
// pin or unpin, close its windows. Dock.qml builds the items for the app it was on.
PopupMenu {
    open: ShellState.dockMenuOpen
    layerName: "robinos-dockmenu"
    at: ShellState.dockMenuAt
    upward: true
    items: ShellState.dockMenuItems
    onDismiss: ShellState.dockMenuOpen = false
}
