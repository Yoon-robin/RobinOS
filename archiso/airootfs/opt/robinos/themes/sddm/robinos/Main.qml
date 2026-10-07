import QtQuick

// RobinOS login screen (SDDM, Qt 6). Matches the shell: zinc colors, Geist,
// dot-grid wallpaper, a centered card. Colors follow desktop/shell/Theme.qml.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#09090b"

    readonly property color fg: "#fafafa"
    readonly property color fgSoft: "#d4d4d8"
    readonly property color muted: "#a1a1aa"
    readonly property color subtle: "#71717a"
    readonly property color surface: Qt.rgba(18 / 255, 18 / 255, 20 / 255, 0.88)
    readonly property color secondary: "#27272a"
    readonly property color border: Qt.rgba(1, 1, 1, 0.10)
    readonly property color input: Qt.rgba(1, 1, 1, 0.15)
    readonly property color accent: config.accent || "#e5484d"
    readonly property color destructive: "#f87171"
    readonly property string font: config.typeface || "Geist"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property var sessionNames: []
    property bool otherUser: userModel.lastUser === ""
    property string message: ""

    readonly property var weekdays: ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]

    function login() {
        const user = root.otherUser ? userField.text.trim() : userModel.lastUser;
        if (user === "") {
            userField.forceActiveFocus();
            return;
        }
        root.message = "";
        sddm.login(user, password.text, root.sessionIndex);
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.message = "비밀번호가 맞지 않아요";
            password.text = "";
            password.forceActiveFocus();
        }
    }

    // Collect session names for the session switcher
    Repeater {
        model: sessionModel

        Item {
            required property int index
            required property string name

            Component.onCompleted: {
                const names = root.sessionNames.slice();
                names[index] = name;
                root.sessionNames = names;
            }
        }
    }

    // ---- Wallpaper: dot grid and a soft light ----
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();
            const light = ctx.createRadialGradient(w / 2, h * 0.45, 0, w / 2, h * 0.45, Math.max(w, h) * 0.55);
            light.addColorStop(0, "rgba(255,255,255,0.05)");
            light.addColorStop(1, "rgba(0,0,0,0)");
            ctx.fillStyle = light;
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = "rgba(255,255,255,0.07)";
            ctx.beginPath();
            for (let y = 11; y < h; y += 22) {
                for (let x = 11; x < w; x += 22) {
                    ctx.moveTo(x + 1, y);
                    ctx.arc(x, y, 1, 0, Math.PI * 2);
                }
            }
            ctx.fill();
        }
    }

    // ---- Clock and login card ----
    Column {
        anchors.centerIn: parent
        spacing: 36

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.fg
                font.family: root.font
                font.pixelSize: 96
                font.weight: Font.Medium
                font.letterSpacing: -4
            }

            Text {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.muted
                font.family: root.font
                font.pixelSize: 16
                font.weight: Font.Medium
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    const now = new Date();
                    clock.text = Qt.formatTime(now, "HH:mm");
                    date.text = (now.getMonth() + 1) + "월 " + now.getDate() + "일 " + root.weekdays[now.getDay()];
                }
            }
        }

        Rectangle {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            width: 380
            height: form.implicitHeight + 48
            radius: 16
            color: root.surface
            border.width: 1
            border.color: root.border

            Column {
                id: form

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                anchors.topMargin: 28
                spacing: 18

                // Avatar and name
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        height: 64
                        radius: 32
                        color: root.secondary
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: root.otherUser ? "?" : userModel.lastUser.charAt(0).toUpperCase()
                            color: root.fg
                            font.family: root.font
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !root.otherUser
                        text: userModel.lastUser
                        color: root.fg
                        font.family: root.font
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                }

                // Username (only when there is no remembered user)
                Column {
                    visible: root.otherUser
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "사용자 이름"
                        color: root.fg
                        font.family: root.font
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: userField.activeFocus ? root.muted : root.input

                        TextInput {
                            id: userField
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.fg
                            font.family: root.font
                            font.pixelSize: 14
                            clip: true
                            KeyNavigation.tab: password
                            Keys.onReturnPressed: password.forceActiveFocus()
                            Keys.onEnterPressed: password.forceActiveFocus()
                        }
                    }
                }

                // Password
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "비밀번호"
                        color: root.fg
                        font.family: root.font
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: root.message !== "" ? root.destructive : password.activeFocus ? root.muted : root.input

                        // Focus ring
                        Rectangle {
                            visible: password.activeFocus
                            anchors.fill: parent
                            anchors.margins: -4
                            radius: 11
                            color: "transparent"
                            border.width: 3
                            border.color: Qt.rgba(161 / 255, 161 / 255, 170 / 255, 0.25)
                        }

                        TextInput {
                            id: password
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: root.fg
                            font.family: root.font
                            font.pixelSize: 14
                            clip: true
                            focus: true
                            onTextChanged: root.message = ""
                            Keys.onReturnPressed: root.login()
                            Keys.onEnterPressed: root.login()

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: password.text === ""
                                text: "비밀번호 입력"
                                color: root.subtle
                                font: password.font
                            }
                        }
                    }

                    Row {
                        visible: root.message !== "" || keyboard.capsLock
                        spacing: 6

                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "triangle-alert"
                            size: 13
                            color: root.message !== "" ? root.destructive : root.muted
                        }

                        Text {
                            text: root.message !== "" ? root.message : "Caps Lock이 켜져 있어요"
                            color: root.message !== "" ? root.destructive : root.muted
                            font.family: root.font
                            font.pixelSize: 12
                        }
                    }
                }

                // Log in
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: loginMouse.pressed ? "#d4d4d8" : loginMouse.containsMouse ? "#e4e4e7" : root.fg

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "로그인"
                            color: "#18181b"
                            font.family: root.font
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "arrow-right"
                            color: "#18181b"
                        }
                    }

                    MouseArea {
                        id: loginMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.login()
                    }
                }

                // Session and user switch
                Item {
                    width: parent.width
                    height: 32

                    Rectangle {
                        anchors.left: parent.left
                        height: 32
                        width: sessionRow.implicitWidth + 20
                        radius: 8
                        color: sessionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        border.width: 1
                        border.color: root.border

                        Row {
                            id: sessionRow
                            anchors.centerIn: parent
                            spacing: 8

                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "monitor"
                                size: 14
                                color: root.fgSoft
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.sessionNames[root.sessionIndex] ?? "세션"
                                color: root.fgSoft
                                font.family: root.font
                                font.pixelSize: 13
                            }

                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "chevron-down"
                                size: 14
                                color: root.subtle
                            }
                        }

                        // Click cycles through installed sessions
                        MouseArea {
                            id: sessionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, root.sessionNames.length)
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.otherUser ? "" : "다른 사용자"
                        color: otherMouse.containsMouse ? root.fg : root.muted
                        font.family: root.font
                        font.pixelSize: 13

                        MouseArea {
                            id: otherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.otherUser = true;
                                userField.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- Corners ----
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: 7
            color: root.accent

            Glyph {
                anchors.centerIn: parent
                name: "mark"
                size: 16
                stroke: 3
                color: "#ffffff"
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "RobinOS"
            color: root.fg
            font.family: root.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        spacing: 8

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: "shield"
            size: 14
            color: root.muted
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "허가받은 환경에서만 쓰는 보안 학습용 시스템이에요"
            color: root.muted
            font.family: root.font
            font.pixelSize: 12
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 8

        Repeater {
            model: [
                { icon: "rotate-ccw", label: "다시 시작", action: "reboot" },
                { icon: "power", label: "전원 끄기", action: "poweroff" }
            ]

            Rectangle {
                id: powerButton

                required property var modelData

                visible: modelData.action === "reboot" ? sddm.canReboot : sddm.canPowerOff
                width: 36
                height: 36
                radius: 8
                color: powerMouse.containsMouse ? root.secondary : Qt.rgba(18 / 255, 18 / 255, 20 / 255, 0.7)
                border.width: 1
                border.color: root.border

                Accessible.role: Accessible.Button
                Accessible.name: modelData.label

                Glyph {
                    anchors.centerIn: parent
                    name: powerButton.modelData.icon
                    size: 15
                    color: root.fgSoft
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (powerButton.modelData.action === "reboot")
                            sddm.reboot();
                        else
                            sddm.powerOff();
                    }
                }
            }
        }
    }
}
