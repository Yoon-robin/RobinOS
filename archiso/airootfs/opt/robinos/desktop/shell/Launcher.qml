import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Command palette launcher (Super+Space): apps, RobinOS lab commands and system actions.
PanelWindow {
    id: root

    readonly property bool open: ShellState.launcherOpen
    property bool mapped: false
    property bool revealed: false
    property var results: []
    property int current: -1

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
    WlrLayershell.namespace: "robinos-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onOpenChanged: {
        if (open) {
            search.text = "";
            refresh();
            mapped = true;
            Qt.callLater(() => {
                root.revealed = true;
                search.forceActiveFocus();
            });
        } else {
            revealed = false;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.dur
        onTriggered: {
            if (!root.open)
                root.mapped = false;
        }
    }

    // ---- Content ----

    readonly property var pinnedApps: ["foot", "org.gnome.Nautilus", "firefox"]
    readonly property var labApps: ["org.wireshark.Wireshark", "ghidra", "virt-manager"]

    readonly property var commands: [
        { key: "lab-start", group: "lab", icon: "flask", title: "웹 보안 랩 시작", subtitle: "Juice Shop · DVWA", badge: "로컬 전용", words: "lab web juice dvwa 랩 실습 docker" },
        { key: "lab-open", group: "lab", icon: "external", title: "Juice Shop 열기", subtitle: "http://localhost:3000", words: "lab juice shop browser 랩" },
        { key: "lab-stop", group: "lab", icon: "circle-stop", title: "웹 보안 랩 중지", subtitle: "robinctl lab stop web", mono: true, words: "lab stop 랩 중지" },
        { key: "snapshot", group: "system", icon: "history", title: "스냅샷 만들기", subtitle: "robinctl snapshot create", mono: true, words: "snapshot snapper btrfs 백업 복구" },
        { key: "update", group: "system", icon: "refresh", title: "시스템 업데이트", subtitle: "업데이트 전에 스냅샷을 자동으로 만들어요", words: "update upgrade pacman 업데이트" },
        { key: "doctor", group: "system", icon: "activity", title: "시스템 점검", subtitle: "robinctl doctor", mono: true, words: "doctor check 점검 진단" },
        { key: "wifi", group: "system", icon: "wifi", title: "Wi-Fi 연결", subtitle: "nmtui", mono: true, words: "wifi network 네트워크 인터넷" },
        { key: "lock", group: "power", icon: "lock", title: "화면 잠금", subtitle: "Super + L", words: "lock 잠금" },
        { key: "logout", group: "power", icon: "log-out", title: "로그아웃", subtitle: "", words: "logout exit 로그아웃" },
        { key: "reboot", group: "power", icon: "rotate-ccw", title: "다시 시작", subtitle: "", words: "reboot restart 재부팅 재시작" },
        { key: "poweroff", group: "power", icon: "power", title: "전원 끄기", subtitle: "", words: "poweroff shutdown 종료 전원" }
    ]

    function appItem(entry) {
        return {
            kind: "app",
            entry: entry,
            title: entry.name,
            subtitle: entry.genericName !== "" && entry.genericName !== entry.name ? entry.genericName : entry.comment,
            appIcon: Quickshell.iconPath(entry.icon, "application-x-executable")
        };
    }

    function commandItem(cmd) {
        return {
            kind: "cmd",
            key: cmd.key,
            icon: cmd.icon,
            title: cmd.title,
            subtitle: cmd.subtitle,
            badge: cmd.badge ?? "",
            mono: cmd.mono ?? false
        };
    }

    function lookup(id) {
        return DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
    }

    function matches(text, query) {
        return (text ?? "").toLowerCase().indexOf(query) !== -1;
    }

    function refresh() {
        const q = search.text.trim().toLowerCase();
        const out = [];

        if (q === "") {
            out.push({ kind: "header", title: "추천" });
            for (const id of pinnedApps) {
                const entry = lookup(id);
                if (entry)
                    out.push(appItem(entry));
            }

            out.push({ kind: "header", title: "보안 랩" });
            out.push(commandItem(commands[0]));
            for (const id of labApps) {
                const entry = lookup(id);
                if (entry)
                    out.push(appItem(entry));
            }

            out.push({ kind: "header", title: "명령" });
            for (const cmd of commands) {
                if (cmd.group === "system" && cmd.key !== "wifi")
                    out.push(commandItem(cmd));
            }
        } else {
            const apps = ShellState.toArray(DesktopEntries.applications.values);
            const starts = [];
            const contains = [];
            for (const entry of apps) {
                const name = entry.name.toLowerCase();
                if (name.startsWith(q))
                    starts.push(entry);
                else if (name.indexOf(q) !== -1 || matches(entry.genericName, q) || matches(entry.comment, q)
                         || matches(entry.keywords.join(" "), q) || matches(entry.id, q))
                    contains.push(entry);
            }
            const found = starts.concat(contains).slice(0, 8);
            if (found.length > 0) {
                out.push({ kind: "header", title: "앱" });
                for (const entry of found)
                    out.push(appItem(entry));
            }

            const cmds = commands.filter(c => matches(c.title, q) || matches(c.subtitle, q) || matches(c.words, q));
            if (cmds.length > 0) {
                out.push({ kind: "header", title: "명령" });
                for (const cmd of cmds)
                    out.push(commandItem(cmd));
            }
        }

        results = out;
        current = nextSelectable(-1, 1);
        list.positionViewAtBeginning();
    }

    function nextSelectable(from, step) {
        let i = from + step;
        while (i >= 0 && i < results.length) {
            if (results[i].kind !== "header")
                return i;
            i += step;
        }
        return from >= 0 && from < results.length ? from : -1;
    }

    function move(step) {
        current = nextSelectable(current, step);
        if (current >= 0)
            list.positionViewAtIndex(current, ListView.Contain);
    }

    function close() {
        ShellState.launcherOpen = false;
    }

    function activate(index) {
        const item = results[index];
        if (!item || item.kind === "header")
            return;
        close();

        if (item.kind === "app") {
            if (item.entry.runInTerminal)
                Quickshell.execDetached(["foot"].concat(item.entry.command));
            else
                item.entry.execute();
            return;
        }

        switch (item.key) {
        case "lab-start":
            ShellState.runInTerminal("robinctl lab start web && printf '\\nJuice Shop  http://localhost:3000\\nDVWA        http://localhost:8080\\n'");
            break;
        case "lab-open":
            ShellState.openUrl("http://localhost:3000");
            break;
        case "lab-stop":
            ShellState.runInTerminal("robinctl lab stop web");
            break;
        case "snapshot":
            ShellState.runInTerminal("sudo robinctl snapshot create");
            break;
        case "update":
            ShellState.runInTerminal("sudo robinctl update");
            break;
        case "doctor":
            ShellState.runInTerminal("robinctl doctor");
            break;
        case "wifi":
            ShellState.runInTerminal("nmtui");
            break;
        case "lock":
            ShellState.lock();
            break;
        case "logout":
            ShellState.logout();
            break;
        case "reboot":
            ShellState.reboot();
            break;
        case "poweroff":
            ShellState.powerOff();
            break;
        }
    }

    // ---- UI ----

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.17)
        width: 640
        height: column.implicitHeight
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        clip: true
        opacity: root.revealed ? 1 : 0
        scale: root.revealed ? 1 : 0.98

        Behavior on opacity {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
        }

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 16
        }

        // Swallow clicks so they don't reach the scrim
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column

            width: parent.width
            spacing: 0

            // Search
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 54

                Icon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: 18
                    color: Theme.muted
                }

                TextInput {
                    id: search

                    anchors.left: searchIcon.right
                    anchors.leftMargin: 12
                    anchors.right: escKey.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    selectionColor: Theme.secondaryHover
                    selectedTextColor: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 15
                    clip: true

                    Accessible.role: Accessible.EditableText
                    Accessible.name: "검색"

                    onTextChanged: root.refresh()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier))) {
                            root.move(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier))) {
                            root.move(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.current);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.close();
                            event.accepted = true;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: search.text === "" && search.preeditText === ""
                        text: "앱, 명령, 랩 검색…"
                        color: Theme.subtle
                        font: search.font
                    }
                }

                Kbd {
                    id: escKey
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "esc"
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Theme.border
                }
            }

            // Results
            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight + 12, 440)
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                leftMargin: 6
                rightMargin: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.results

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool isHeader: modelData.kind === "header"
                    readonly property bool selected: index === root.current

                    width: list.width - 12
                    height: isHeader ? 32 : 44

                    Text {
                        visible: row.isHeader
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: row.modelData.title
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        visible: !row.isHeader
                        anchors.fill: parent
                        radius: Theme.radiusMd
                        color: row.selected ? Theme.secondary : "transparent"

                        Accessible.role: Accessible.Button
                        Accessible.name: row.modelData.title

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 7
                                color: row.selected ? Theme.bg : Theme.raised
                                border.width: 1
                                border.color: Theme.border

                                Icon {
                                    visible: row.modelData.kind === "cmd"
                                    anchors.centerIn: parent
                                    name: row.modelData.icon ?? ""
                                    size: 15
                                    color: Theme.fgSoft
                                }

                                IconImage {
                                    visible: row.modelData.kind === "app"
                                    anchors.centerIn: parent
                                    implicitSize: 20
                                    source: row.modelData.appIcon ?? ""
                                }
                            }

                            Text {
                                text: row.modelData.title ?? ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.subtitle ?? ""
                                color: Theme.subtle
                                font.family: row.modelData.mono ? Theme.mono : Theme.font
                                font.pixelSize: row.modelData.mono ? 12 : 13
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: (row.modelData.badge ?? "") !== ""
                                implicitWidth: badgeRow.implicitWidth + 16
                                implicitHeight: 22
                                radius: 11
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.borderStrong

                                RowLayout {
                                    id: badgeRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        implicitWidth: 6
                                        implicitHeight: 6
                                        radius: 3
                                        color: Theme.success
                                    }

                                    Text {
                                        text: row.modelData.badge ?? ""
                                        color: Theme.fgSoft
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = row.index
                            onClicked: root.activate(row.index)
                        }
                    }
                }
            }

            Text {
                visible: root.results.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 18
                Layout.bottomMargin: 24
                text: "일치하는 항목이 없어요"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Theme.raised

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Mark {
                        size: 16
                    }

                    Text {
                        text: "RobinOS 런처"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    RowLayout {
                        spacing: 6
                        Kbd { text: "↑↓" }
                        Text { text: "이동"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                    }

                    RowLayout {
                        spacing: 6
                        Kbd { text: "↵" }
                        Text { text: "열기"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}
