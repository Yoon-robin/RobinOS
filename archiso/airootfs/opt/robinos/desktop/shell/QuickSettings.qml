import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import "keys.js" as Keyboard

// Quick settings popover under the bar's status button (Super+S).
PanelWindow {
    id: root

    readonly property bool open: ShellState.quickSettingsOpen
    property bool mapped: false
    property bool revealed: false
    property bool confirmPower: false

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
    WlrLayershell.namespace: "robinos-quicksettings"
    // Only while open: during the fade-out the keyboard already goes back, so a window
    // started from here (a terminal, an app) gets the focus (boot test, 2026-10-10)
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            // Alt+F4 with no window asks for the power menu, like Windows' shutdown dialog
            confirmPower = ShellState.powerMenuRequested;
            ShellState.powerMenuRequested = false;
            ShellState.refreshBrightness();
            ShellState.refreshLab();
            ShellState.checkUpdates(false);
            mapped = true;
            Qt.callLater(() => {
                root.revealed = true;
                card.forceActiveFocus();
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

    function close() {
        ShellState.quickSettingsOpen = false;
    }

    // Click anywhere outside the card to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 344
        height: content.implicitHeight + 24
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: root.revealed ? 1 : 0
        focus: true

        transform: Translate {
            y: root.revealed ? 0 : -6

            Behavior on y {
                NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
        }

        layer.enabled: !Theme.lowPower
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12
        }

        Keys.onEscapePressed: root.close()

        // Keep clicks inside the card from closing it
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 12

            // ---- User and power ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                spacing: 10

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: Theme.secondary

                    Text {
                        anchors.centerIn: parent
                        text: ShellState.userName.charAt(0).toUpperCase()
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: ShellState.userName
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: ShellState.hostName
                        color: Theme.muted
                        font.family: Theme.mono
                        font.pixelSize: 12
                    }
                }

                IconButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    outline: true
                    icon: "lock"
                    label: "화면 잠금"
                    onClicked: {
                        root.close();
                        ShellState.lock();
                    }
                }

                IconButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    outline: true
                    active: root.confirmPower
                    icon: "power"
                    label: "전원 메뉴"
                    onClicked: root.confirmPower = !root.confirmPower
                }
            }

            // ---- Power menu (shown after pressing the power button) ----
            RowLayout {
                visible: root.confirmPower
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { key: "logout", icon: "log-out", title: "로그아웃" },
                        { key: "reboot", icon: "rotate-ccw", title: "다시 시작" },
                        { key: "poweroff", icon: "power", title: "전원 끄기" }
                    ]

                    Rectangle {
                        id: powerButton

                        required property var modelData
                        readonly property bool danger: modelData.key === "poweroff"

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radiusMd
                        color: danger ? (powerMouse.containsMouse ? "#b91c1c" : Theme.destructiveSolid)
                                      : (powerMouse.containsMouse ? Theme.secondaryHover : Theme.secondary)

                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.title

                        function press() {
                            root.close();
                            if (modelData.key === "logout")
                                ShellState.logout();
                            else if (modelData.key === "reboot")
                                ShellState.reboot();
                            else
                                ShellState.powerOff();
                        }

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                powerButton.press();
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: powerButton.radius
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                name: powerButton.modelData.icon
                                size: 14
                                color: powerButton.danger ? "#ffffff" : Theme.fg
                            }

                            Text {
                                text: powerButton.modelData.title
                                color: powerButton.danger ? "#ffffff" : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerButton.press()
                        }
                    }
                }
            }

            // ---- Updates waiting (ShellState.updateCount) ----
            Rectangle {
                id: updateButton

                visible: ShellState.updateCount > 0
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusMd
                color: updateMouse.containsMouse ? Theme.secondaryHover : Theme.secondary

                Accessible.role: Accessible.Button
                Accessible.name: "업데이트 " + ShellState.updateCount + "개 설치하기"

                function start() {
                    root.close();
                    ShellState.runInTerminal("sudo robinctl update");
                }

                activeFocusOnTab: true
                Keys.onPressed: event => {
                    if (Keyboard.activates(event)) {
                        updateButton.start();
                        event.accepted = true;
                    }
                }

                FocusRing {
                    baseRadius: updateButton.radius
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Icon {
                        name: "refresh"
                        color: Theme.fg
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "업데이트 " + ShellState.updateCount + "개가 있어요"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "지금 업데이트"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: updateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: updateButton.start()
                }
            }

            // ---- Toggles ----
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: ShellState.netIcon
                    title: ShellState.wiredDevice ? "네트워크" : "Wi-Fi"
                    subtitle: ShellState.netLabel
                    checked: ShellState.wiredDevice !== null || (ShellState.wifiDevice !== null && ShellState.wifiEnabled)
                    enabled: ShellState.wifiDevice !== null || ShellState.wiredDevice !== null
                    hasDetail: true
                    onToggled: {
                        if (ShellState.wifiDevice)
                            ShellState.toggleWifi();
                    }
                    onDetailRequested: ShellState.openDetail("wifi")
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: ShellState.btEnabled ? "bluetooth" : "bluetooth-off"
                    title: "블루투스"
                    subtitle: ShellState.btAdapter ? (ShellState.btEnabled ? "켜짐" : "꺼짐") : "장치 없음"
                    checked: ShellState.btEnabled
                    enabled: ShellState.btAdapter !== null
                    hasDetail: true
                    onToggled: ShellState.toggleBluetooth()
                    onDetailRequested: ShellState.openDetail("bluetooth")
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: ShellState.dnd ? "bell-off" : "bell"
                    title: "방해 금지"
                    subtitle: ShellState.dnd ? "켜짐" : "꺼짐"
                    checked: ShellState.dnd
                    onToggled: ShellState.dnd = !ShellState.dnd
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Theme.dark ? "moon" : "sun"
                    title: "다크 모드"
                    subtitle: Theme.dark ? "켜짐" : "꺼짐"
                    checked: Theme.dark
                    onToggled: Theme.setDark(!Theme.dark)
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "grid"
                    title: "창 자동 정렬"
                    subtitle: ShellState.tiling ? "새 창을 나란히 배치" : "꺼짐 · 자유 배치"
                    checked: ShellState.tiling
                    onToggled: ShellState.setTiling(!ShellState.tiling)
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "monitor"
                    title: "화면 꺼짐 방지"
                    subtitle: ShellState.keepAwake ? "켜짐" : "꺼짐"
                    checked: ShellState.keepAwake
                    onToggled: ShellState.keepAwake = !ShellState.keepAwake
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "sunset"
                    title: "야간 모드"
                    subtitle: ShellState.inVm ? "VM에서는 안 돼요" : ShellState.nightLight ? "켜짐 · 따뜻한 색" : "꺼짐"
                    checked: ShellState.nightLight
                    onToggled: ShellState.toggleNightLight()
                }

                ToggleTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "plane"
                    title: "비행기 모드"
                    subtitle: ShellState.airplane ? "켜짐 · Wi-Fi, 블루투스 끔" : "꺼짐"
                    checked: ShellState.airplane
                    onToggled: ShellState.toggleAirplane()
                }
            }

            // ---- Power mode (power-profiles-daemon), like Windows' power mode ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                spacing: 6

                Text {
                    Layout.rightMargin: 4
                    text: "전원 모드"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Repeater {
                    // VMs and many desktops have no performance profile; it is hidden there
                    model: [
                        { profile: PowerProfile.PowerSaver, title: "절전" },
                        { profile: PowerProfile.Balanced, title: "균형" },
                        { profile: PowerProfile.Performance, title: "최고 성능" }
                    ].filter(mode => mode.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

                    Rectangle {
                        id: modeButton

                        required property var modelData
                        readonly property bool selected: PowerProfiles.profile === modelData.profile

                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.radiusMd
                        color: selected ? Theme.primary : (modeMouse.containsMouse ? Theme.secondaryHover : Theme.secondary)

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: "전원 모드 " + modelData.title
                        Accessible.checked: selected

                        function choose() {
                            PowerProfiles.profile = modeButton.modelData.profile;
                        }

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                modeButton.choose();
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: modeButton.radius
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modeButton.modelData.title
                            color: modeButton.selected ? Theme.primaryFg : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: modeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modeButton.choose()
                        }
                    }
                }
            }

            // ---- Display scale (ShellState.setScale), like Windows' 배율 ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                spacing: 6

                Text {
                    Layout.rightMargin: 4
                    text: "화면 배율"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Repeater {
                    model: ShellState.scaleOptions

                    Rectangle {
                        id: scaleButton

                        required property real modelData
                        // Hyprland may round to a scale that fits the screen exactly
                        readonly property bool selected: Math.abs(ShellState.displayScale - modelData) < 0.06

                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.radiusMd
                        color: selected ? Theme.primary : (scaleMouse.containsMouse ? Theme.secondaryHover : Theme.secondary)

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: "화면 배율 " + Math.round(modelData * 100) + "%"
                        Accessible.checked: selected

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                ShellState.setScale(scaleButton.modelData);
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: scaleButton.radius
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(scaleButton.modelData * 100) + "%"
                            color: scaleButton.selected ? Theme.primaryFg : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: scaleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.setScale(scaleButton.modelData)
                        }
                    }
                }
            }

            // ---- Sliders ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.topMargin: 2
                spacing: 14

                RowLayout {
                    visible: ShellState.hasBacklight
                    Layout.fillWidth: true
                    spacing: 12

                    Icon {
                        name: "sun"
                        color: Theme.muted
                    }

                    QsSlider {
                        Layout.fillWidth: true
                        label: "밝기"
                        value: ShellState.brightness
                        onMoved: value => ShellState.setBrightness(value)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    IconButton {
                        implicitWidth: 20
                        implicitHeight: 20
                        icon: ShellState.volumeIcon
                        iconColor: Theme.muted
                        label: ShellState.muted ? "음소거 해제" : "음소거"
                        onClicked: ShellState.toggleMute()
                    }

                    QsSlider {
                        Layout.fillWidth: true
                        label: "음량"
                        enabled: ShellState.audioReady
                        value: ShellState.muted ? 0 : ShellState.volume
                        onMoved: value => ShellState.setVolume(value)
                    }

                    // Output and input devices and each app's volume (SoundPanel.qml)
                    IconButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        icon: "chevron-right"
                        iconSize: 14
                        iconColor: Theme.muted
                        label: "소리 설정"
                        onClicked: ShellState.openDetail("sound")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            // ---- Accent color ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: "강조 색상"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Repeater {
                    model: ["red", "orange", "green", "blue", "violet", "neutral"]

                    Rectangle {
                        id: swatch

                        required property string modelData
                        readonly property bool selected: Theme.accentName === modelData

                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: "transparent"
                        border.width: selected ? 2 : 0
                        border.color: Theme.accents[modelData]

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: Theme.accentLabels[modelData]
                        Accessible.checked: selected

                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (Keyboard.activates(event)) {
                                Theme.setAccent(swatch.modelData);
                                event.accepted = true;
                            }
                        }

                        FocusRing {
                            baseRadius: swatch.radius
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: swatch.selected ? 14 : 18
                            height: width
                            radius: width / 2
                            color: Theme.accents[swatch.modelData]

                            Behavior on width {
                                NumberAnimation { duration: Theme.durFast }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setAccent(swatch.modelData)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            // ---- Local lab status ----
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                Layout.bottomMargin: 2
                spacing: 8

                Rectangle {
                    implicitWidth: labRow.implicitWidth + 18
                    implicitHeight: 24
                    radius: 12
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.borderStrong

                    RowLayout {
                        id: labRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: ShellState.labRunning ? Theme.success : Theme.subtle
                        }

                        Text {
                            text: ShellState.labRunning ? "웹 보안 랩 실행 중" : "실행 중인 랩 없음"
                            color: Theme.fgSoft
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    id: labText

                    text: ShellState.labRunning ? "localhost:3000" : "랩 시작"
                    color: labLink.containsMouse ? Theme.fg : Theme.muted
                    font.family: ShellState.labRunning ? Theme.mono : Theme.font
                    font.pixelSize: 12
                    font.underline: labLink.containsMouse

                    Accessible.role: Accessible.Link
                    Accessible.name: ShellState.labRunning ? "Juice Shop 열기" : "웹 보안 랩 시작"

                    function open() {
                        root.close();
                        if (ShellState.labRunning)
                            ShellState.openUrl("http://localhost:3000");
                        else
                            ShellState.runInTerminal("robinctl lab start web");
                    }

                    activeFocusOnTab: true
                    Keys.onPressed: event => {
                        if (Keyboard.activates(event)) {
                            labText.open();
                            event.accepted = true;
                        }
                    }

                    FocusRing {
                        baseRadius: 4
                    }

                    MouseArea {
                        id: labLink
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: labText.open()
                    }
                }
            }
        }
    }
}
