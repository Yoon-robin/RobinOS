import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
    // Where the pointer was first seen after opening, in window coordinates
    // ((-1, -1) until then), and whether it has moved away from there since
    property point pointer: Qt.point(-1, -1)
    property bool pointerMoved: false

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
            pointer = Qt.point(-1, -1);
            pointerMoved = false;
            if (clipboardMode) {
                clips = [];
                clipList.running = true;
            }
            ShellState.refreshLearn();
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

    // ---- Clipboard history (Win+V) ----
    // robinos.lua keeps what is copied with cliphist in $XDG_RUNTIME_DIR, so it is
    // gone after logging out; cliphist skips what password managers mark sensitive.

    readonly property bool clipboardMode: ShellState.launcherClipboard
    readonly property string cliphist: "cliphist -db-path \"${XDG_RUNTIME_DIR:-/tmp}/robinos-cliphist.db\""
    property var clips: []

    Process {
        id: clipList

        command: ["sh", "-c", root.cliphist + " list 2>/dev/null | head -n 50"]
        stdout: StdioCollector {
            id: clipOut

            onStreamFinished: {
                const clips = [];
                for (const line of clipOut.text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab > 0 && /^[0-9]+$/.test(line.slice(0, tab)))
                        clips.push({ id: line.slice(0, tab), text: line.slice(tab + 1) });
                }
                root.clips = clips;
                if (root.open)
                    root.refresh();
            }
        }
    }

    function clipItems(q) {
        const out = [];
        const shown = root.clips.filter(clip => q === "" || matches(clip.text, q));
        let title = "클립보드 기록 · Enter로 다시 복사해요";
        if (clipList.running)
            title = "클립보드 기록을 불러오는 중이에요";
        else if (root.clips.length === 0)
            title = "아직 복사한 것이 없어요. 복사하면 여기에 쌓여요";
        else if (shown.length === 0)
            title = "찾는 기록이 없어요";
        out.push({ kind: "header", title: title });
        for (const clip of shown)
            out.push({ kind: "clip", id: clip.id, icon: "clipboard", title: clip.text, subtitle: "" });
        return out;
    }

    // The progress file loads after the list is built when the launcher opens
    Connections {
        target: ShellState

        function onLearnDoneChanged() {
            if (root.open && search.text === "")
                root.refresh();
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
    // foot also installs a client and a server entry; the client fails without a
    // running server, and both read as "Terminal" next to the real one
    readonly property var hiddenApps: ["footclient", "foot-server"]
    readonly property var labApps: ["org.wireshark.Wireshark", "ghidra", "virt-manager"]

    readonly property var commands: [
        { key: "learn", group: "learn", icon: "graduation-cap", title: "학습 미션", subtitle: "학습 센터: 리눅스·네트워크·포렌식·리버싱·웹 기초, 터미널에서 풀면 robinctl이 확인해요", words: "learn mission tutorial linux network forensics reversing web http 학습 센터 미션 공부 튜토리얼 리눅스 기초 네트워크 포렌식 리버싱 웹" },
        { key: "ctf", group: "lab", icon: "flag", title: "입문 CTF", subtitle: "미션에서 배운 걸로 플래그 5개 찾기", badge: "로컬 전용", words: "ctf flag capture the flag 플래그 문제 해킹 대회" },
        { key: "lab-start", group: "lab", icon: "flask", title: "웹 보안 랩 시작", subtitle: "Juice Shop · DVWA", badge: "로컬 전용", words: "lab web juice dvwa 랩 실습 docker" },
        { key: "lab-open", group: "lab", icon: "external", title: "Juice Shop 열기", subtitle: "http://localhost:3000", words: "lab juice shop browser 랩" },
        { key: "lab-stop", group: "lab", icon: "circle-stop", title: "웹 보안 랩 중지", subtitle: "robinctl lab stop web", mono: true, words: "lab stop 랩 중지" },
        { key: "snapshot", group: "system", icon: "history", title: "스냅샷 만들기", subtitle: "robinctl snapshot create", mono: true, words: "snapshot snapper btrfs 백업 복구" },
        { key: "update", group: "system", icon: "refresh", title: "시스템 업데이트", subtitle: "업데이트 전에 스냅샷을 자동으로 만들어요", words: "update upgrade pacman 업데이트" },
        { key: "doctor", group: "system", icon: "activity", title: "시스템 점검", subtitle: "robinctl doctor", mono: true, words: "doctor check 점검 진단" },
        { key: "wifi", group: "system", icon: "wifi", title: "Wi-Fi 연결", subtitle: "nmtui", mono: true, words: "wifi network 네트워크 인터넷" },
        { key: "screenshot", group: "system", icon: "scan", title: "영역 스크린샷", subtitle: "Win + Shift + S", words: "screenshot capture 스크린샷 캡처 화면 캡처" },
        { key: "settings", group: "system", icon: "sliders", title: "빠른 설정", subtitle: "Win + S", words: "settings quick 설정 빠른 설정 테마 다크 모드" },
        { key: "install", group: "live", icon: "download", title: "RobinOS 설치", subtitle: "이 컴퓨터에 설치해요", words: "install installer setup 설치 설치기 하드 디스크 윈도우 옆" },
        { key: "welcome", group: "system", icon: "sparkles", title: "환영 마법사", subtitle: "테마, 한/영 키, 단축키 안내", words: "welcome tour setup 환영 마법사 처음 시작 안내 투어 한영" },
        { key: "lock", group: "power", icon: "lock", title: "화면 잠금", subtitle: "Win + L", words: "lock 잠금" },
        { key: "logout", group: "power", icon: "log-out", title: "로그아웃", subtitle: "", words: "logout exit 로그아웃" },
        { key: "reboot", group: "power", icon: "rotate-ccw", title: "다시 시작", subtitle: "", words: "reboot restart 재부팅 재시작" },
        { key: "poweroff", group: "power", icon: "power", title: "전원 끄기", subtitle: "", words: "poweroff shutdown 종료 전원" }
    ]

    // Names people know from Windows, mapped to the app or command that does the
    // same job here. Searching "메모장" or "notepad" finds the text editor and says so.
    readonly property var windowsNames: [
        { win: "메모장", words: "메모장 notepad 워드패드 wordpad", app: "org.gnome.TextEditor" },
        { win: "작업 관리자", words: "작업 관리자 task manager taskmgr 리소스 모니터 resource monitor", app: "io.missioncenter.MissionCenter" },
        { win: "파일 탐색기", words: "파일 탐색기 explorer 내 pc 내 컴퓨터 this pc my computer", app: "org.gnome.Nautilus" },
        { win: "명령 프롬프트", words: "명령 프롬프트 command prompt cmd powershell 파워셸", app: "foot" },
        { win: "Edge", words: "edge 엣지 internet explorer 인터넷 익스플로러 chrome 크롬", app: "firefox" },
        { win: "사진 앱", words: "사진 photos 사진 보기 image viewer", app: "org.gnome.Loupe" },
        { win: "반디집", words: "반디집 bandizip 알집 7-zip 7zip winrar 압축 풀기", app: "org.gnome.FileRoller" },
        { win: "볼륨 믹서", words: "볼륨 믹서 volume mixer 소리 설정 sound settings", app: "org.pulseaudio.pavucontrol" },
        { win: "Acrobat Reader", words: "acrobat 아크로뱃 adobe reader pdf 뷰어", app: "org.gnome.Evince" },
        { win: "캡처 도구", words: "캡처 도구 snipping tool 캡처 스크린샷 screenshot", cmd: "screenshot" },
        { win: "계산기", words: "계산기 calc calculator", app: "org.gnome.Calculator" },
        { win: "디스크 관리", words: "디스크 관리 disk management diskmgmt 포맷 format usb 파티션 partition", app: "org.gnome.DiskUtility" },
        { win: "Word", words: "워드 word 문서 작성 docx 오피스 office", app: "libreoffice-writer" },
        { win: "Excel", words: "엑셀 excel 스프레드시트 spreadsheet xlsx 오피스 office", app: "libreoffice-calc" },
        { win: "PowerPoint", words: "파워포인트 powerpoint ppt pptx 프레젠테이션 발표 오피스 office", app: "libreoffice-impress" },
        { win: "Microsoft Store", words: "microsoft store 마이크로소프트 스토어 앱 스토어 app store 프로그램 설치 앱 설치 flathub", app: "org.gnome.Software" },
        { win: "장치 및 프린터", words: "장치 및 프린터 devices and printers 프린터 printer 인쇄 print", app: "system-config-printer" },
        { win: "제어판", words: "제어판 control panel 윈도우 설정 windows settings", cmd: "settings" }
    ]

    function windowsHint(name) {
        return "윈도우의 " + name + "에 해당해요";
    }

    function appItem(entry) {
        return {
            kind: "app",
            entry: entry,
            title: entry.name,
            subtitle: entry.genericName !== "" && entry.genericName !== entry.name ? entry.genericName : entry.comment,
            appIcon: Quickshell.iconPath(entry.icon, "application-x-executable")
        };
    }

    // The learning missions show how far the user got once they started
    function learnSubtitle(cmd) {
        const done = ShellState.learnDone;
        const total = ShellState.learnTotal;
        if (done >= total)
            return done + "/" + total + " 모두 끝냈어요 · 다음은 웹 보안 랩이에요";
        if (done > 0)
            return done + "/" + total + " 완료 · 이어서 풀어요";
        return cmd.subtitle;
    }

    function commandItem(cmd) {
        return {
            kind: "cmd",
            key: cmd.key,
            icon: cmd.icon,
            title: cmd.title,
            subtitle: cmd.key === "learn" ? learnSubtitle(cmd) : cmd.subtitle,
            badge: cmd.badge ?? "",
            mono: cmd.mono ?? false
        };
    }

    function lookup(id) {
        return DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
    }

    function command(key) {
        return commands.find(c => c.key === key);
    }

    function matches(text, query) {
        return (text ?? "").toLowerCase().indexOf(query) !== -1;
    }

    function refresh() {
        const q = search.text.trim().toLowerCase();
        const out = [];

        if (clipboardMode) {
            results = clipItems(q);
            current = nextSelectable(-1, 1);
            list.positionViewAtBeginning();
            return;
        }

        if (q === "") {
            out.push({ kind: "header", title: "추천" });
            if (ShellState.isLive)
                out.push(commandItem(command("install")));
            for (const id of pinnedApps) {
                const entry = lookup(id);
                if (entry)
                    out.push(appItem(entry));
            }
            out.push(commandItem(command("learn")));

            out.push({ kind: "header", title: "보안 랩" });
            out.push(commandItem(command("ctf")));
            out.push(commandItem(command("lab-start")));
            for (const id of labApps) {
                const entry = lookup(id);
                if (entry)
                    out.push(appItem(entry));
            }

            out.push({ kind: "header", title: "명령" });
            for (const key of ["snapshot", "update", "doctor"])
                out.push(commandItem(command(key)));
        } else {
            // Windows names first. A single Latin letter would match too much.
            const shownApps = {};
            const shownCmds = {};
            const known = [];
            if (q.length >= 2 || /[^\x00-\x7f]/.test(q)) {
                for (const name of windowsNames.filter(w => matches(w.words, q))) {
                    let item = null;
                    if (name.cmd) {
                        if (!shownCmds[name.cmd]) {
                            item = commandItem(command(name.cmd));
                            shownCmds[name.cmd] = true;
                        }
                    } else {
                        const entry = lookup(name.app);
                        if (entry && !shownApps[entry.id]) {
                            item = appItem(entry);
                            shownApps[entry.id] = true;
                        }
                    }
                    if (item) {
                        item.subtitle = windowsHint(name.win);
                        known.push(item);
                    }
                }
            }
            if (known.length > 0) {
                out.push({ kind: "header", title: "윈도우에서 쓰던 이름" });
                for (const item of known)
                    out.push(item);
            }

            const apps = ShellState.toArray(DesktopEntries.applications.values);
            const starts = [];
            const contains = [];
            for (const entry of apps) {
                if (shownApps[entry.id] || hiddenApps.indexOf(entry.id) !== -1)
                    continue;
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

            const cmds = commands.filter(c => !shownCmds[c.key] && (c.group !== "live" || ShellState.isLive)
                                         && (matches(c.title, q) || matches(c.subtitle, q) || matches(c.words, q)));
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

        if (item.kind === "clip") {
            Quickshell.execDetached(["sh", "-c", root.cliphist + " decode " + item.id + " | wl-copy"]);
            return;
        }

        if (item.kind === "app") {
            if (item.entry.runInTerminal)
                Quickshell.execDetached(["foot"].concat(ShellState.toArray(item.entry.command)));
            else
                item.entry.execute();
            return;
        }

        switch (item.key) {
        case "learn":
            ShellState.openLearnCenter();
            break;
        case "screenshot":
            // Wait for the launcher to fade out, or it would be in the picture
            Quickshell.execDetached(["sh", "-c", "sleep 0.4; exec /usr/share/robinos/bin/robinos-screenshot region"]);
            break;
        case "settings":
            ShellState.toggleQuickSettings();
            break;
        case "welcome":
            ShellState.openWelcome();
            break;
        case "install":
            ShellState.openInstaller();
            break;
        case "ctf":
            ShellState.openTerminal("robinctl ctf");
            break;
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
                        text: root.clipboardMode ? "클립보드 기록 검색…" : "앱, 명령, 랩 검색…"
                        color: Theme.muted
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
                                    visible: row.modelData.kind === "cmd" || row.modelData.kind === "clip"
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
                                // A copied paragraph is one long line; keep it inside the row
                                Layout.maximumWidth: row.width - 70
                                text: row.modelData.title ?? ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.subtitle ?? ""
                                color: Theme.muted
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
                            // The list also gets hover events when it opens under a pointer
                            // that stays still, and the card's scale-in animation makes the
                            // mapped position wobble by fractions of a pixel. Select by hover
                            // only once the mouse really moves (3 px from where it was first
                            // seen), so Enter right after opening picks the first result.
                            onPositionChanged: mouse => {
                                const p = mapToItem(null, mouse.x, mouse.y);
                                if (root.pointer.x < 0)
                                    root.pointer = p;
                                else if (Math.abs(p.x - root.pointer.x) + Math.abs(p.y - root.pointer.y) >= 3)
                                    root.pointerMoved = true;
                                if (root.pointerMoved)
                                    root.current = row.index;
                            }
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
