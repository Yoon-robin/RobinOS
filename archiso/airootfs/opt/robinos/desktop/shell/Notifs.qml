pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Desktop notification server (org.freedesktop.Notifications).
Singleton {
    id: root

    readonly property var list: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    function clearAll() {
        const items = ShellState.toArray(server.trackedNotifications.values);
        for (let i = 0; i < items.length; i++)
            items[i].dismiss();
    }

    // Icon source for a notification: its image, an absolute icon path, or a theme icon.
    function iconSource(n) {
        if (n.image && n.image.length > 0)
            return n.image;
        if (!n.appIcon || n.appIcon.length === 0)
            return "";
        if (n.appIcon.startsWith("/"))
            return "file://" + n.appIcon;
        if (n.appIcon.indexOf("://") !== -1)
            return n.appIcon;
        return Quickshell.iconPath(n.appIcon, true);
    }

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }
}
