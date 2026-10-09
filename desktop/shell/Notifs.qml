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

    // A history entry's "default" action while its notification is still alive (the
    // sender waits for it, like the toast click); null once it expired.
    function defaultAction(entry) {
        const actions = entry.notification ? entry.notification.actions : null;
        if (!actions)
            return null;
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                return actions[i];
        }
        return null;
    }

    function canOpen(entry) {
        return !!defaultAction(entry) || entry.open !== "" || (entry.desktopEntry !== "" && !!DesktopEntries.byId(entry.desktopEntry));
    }

    // A click on an old notification, like Windows' notification center: the sender's
    // default action, else the file it pointed at (x-robinos-open hint, e.g. a
    // screenshot), else the app that sent it. Returns whether anything opened.
    function openEntry(entry) {
        const action = defaultAction(entry);
        if (action) {
            action.invoke();
            return true;
        }
        if (entry.open !== "") {
            Quickshell.execDetached(["xdg-open", entry.open]);
            return true;
        }
        const app = entry.desktopEntry !== "" ? DesktopEntries.byId(entry.desktopEntry) : null;
        if (app) {
            app.execute();
            return true;
        }
        return false;
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
            // Only a local file: the hint opens on a click, so no URLs or programs
            const open = String((notification.hints ?? {})["x-robinos-open"] ?? "");
            const entry = {
                summary: notification.summary,
                body: notification.body,
                appName: notification.appName,
                icon: root.iconSource(notification),
                time: new Date(),
                notification: notification,
                open: open.startsWith("/") ? open : "",
                desktopEntry: notification.desktopEntry ?? ""
            };
            root.history = [entry].concat(root.history).slice(0, 30);
            if (!ShellState.notifCenterOpen)
                root.unread++;
        }
    }
}
