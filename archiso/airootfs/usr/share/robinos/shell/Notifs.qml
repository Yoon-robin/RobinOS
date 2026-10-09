pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Desktop notification server (org.freedesktop.Notifications).
Singleton {
    id: root

    readonly property var list: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    // What came in since login, newest first, kept after the toasts go away so the
    // notification center (NotificationCenter.qml, Win+N) can show it again
    property var history: []
    // Arrived since the notification center was last opened (the bar's dot)
    property int unread: 0

    function clearHistory() {
        history = [];
        unread = 0;
        clearAll();
    }

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
            const entry = {
                summary: notification.summary,
                body: notification.body,
                appName: notification.appName,
                icon: root.iconSource(notification),
                time: new Date()
            };
            root.history = [entry].concat(root.history).slice(0, 30);
            if (!ShellState.notifCenterOpen)
                root.unread++;
        }
    }
}
