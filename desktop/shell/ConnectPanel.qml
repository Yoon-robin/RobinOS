import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth

// Wi-Fi networks or Bluetooth devices to connect to, like the lists behind the
// arrows of Windows' quick settings. Opened from the quick settings tiles' detail
// arrow (ShellState.openConnect("wifi" | "bluetooth")). A secured network asks for
// its password inline; nmtui stays one click away for anything else.
PanelWindow {
    id: root

    readonly property bool open: ShellState.connectMode !== ""
    readonly property bool wifi: shownMode === "wifi"
    // Kept while the card fades out, so the content doesn't jump
    property string shownMode: "wifi"
    property bool mapped: false
    property bool revealed: false
    // The secured network the password field is open for
    property var pskNetwork: null

    readonly property var wifiDevice: ShellState.wifiDevice
    readonly property var adapter: ShellState.btAdapter

    readonly property var networks: {
        if (!wifiDevice)
            return [];
        return ShellState.toArray(wifiDevice.networks.values).filter(n => (n.name ?? "") !== "")
            .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }

    readonly property var devices: {
        if (!adapter)
            return [];
        return ShellState.toArray(adapter.devices.values)
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name ?? "").localeCompare(b.name ?? ""));
    }

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
    WlrLayershell.namespace: "robinos-connect"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenChanged: {
        if (open) {
            shownMode = ShellState.connectMode;
            pskNetwork = null;
            mapped = true;
            Qt.callLater(() => {
                root.revealed = true;
                card.forceActiveFocus();
            });
        } else {
            revealed = false;
            hideTimer.restart();
        }
        // Look for networks and devices only while the list is on screen
        if (wifiDevice)
            wifiDevice.scannerEnabled = open && wifi;
        if (adapter && adapter.enabled)
            adapter.discovering = open && !wifi;
    }

    // Turned on from the panel's own button: start looking right away
    Connections {
        target: root.adapter

        function onEnabledChanged() {
            if (root.adapter.enabled)
                root.adapter.discovering = root.open && !root.wifi;
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
        ShellState.connectMode = "";
    }

    function chooseNetwork(n) {
        if (n.connected)
            n.disconnect();
        else if (n.known || n.security === WifiSecurityType.Open)
            n.connect();
        else
            pskNetwork = pskNetwork === n ? null : n;
    }

    function chooseDevice(d) {
        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else
            d.pair();
    }

    function deviceStatus(d) {
        if (d.pairing)
            return "연결하는 중…";
        if (d.connected)
            return d.batteryAvailable ? "연결됨 · 배터리 " + Math.round(d.battery * 100) + "%" : "연결됨";
        return d.paired ? "저장됨 · 누르면 연결해요" : "누르면 연결해요";
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
        width: 340
        height: Math.min(content.implicitHeight + 28, parent.height - Theme.barHeight - 120)
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        opacity: root.revealed ? 1 : 0
        focus: true
        clip: true

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
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.wifi ? "Wi-Fi" : "블루투스"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                ActionButton {
                    visible: root.wifi ? root.wifiDevice !== null : root.adapter !== null
                    variant: "outline"
                    implicitHeight: 28
                    text: (root.wifi ? ShellState.wifiEnabled : ShellState.btEnabled) ? "끄기" : "켜기"
                    onClicked: root.wifi ? ShellState.toggleWifi() : ShellState.toggleBluetooth()
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: root.wifi ? (root.wifiDevice === null || !ShellState.wifiEnabled || root.networks.length === 0)
                                   : (root.adapter === null || !ShellState.btEnabled || root.devices.length === 0)
                text: {
                    if (root.wifi) {
                        if (root.wifiDevice === null)
                            return ShellState.wiredDevice ? "Wi-Fi 장치가 없어요. 지금은 유선으로 연결돼 있어요." : "Wi-Fi 장치가 없어요.";
                        return ShellState.wifiEnabled ? "주변 네트워크를 찾는 중이에요…" : "Wi-Fi가 꺼져 있어요.";
                    }
                    if (root.adapter === null)
                        return "블루투스 장치가 없어요.";
                    return ShellState.btEnabled ? "주변 장치를 찾는 중이에요. 이어폰은 연결 모드로 두세요." : "블루투스가 꺼져 있어요.";
                }
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            // ---- Wi-Fi networks ----
            Repeater {
                model: root.wifi && ShellState.wifiEnabled ? root.networks.slice(0, 10) : []

                ColumnLayout {
                    id: netItem

                    required property var modelData
                    readonly property bool secured: modelData.security !== WifiSecurityType.Open

                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: Theme.radiusMd
                        color: netMouse.containsMouse ? Theme.hover : netItem.modelData.connected ? Theme.raised : "transparent"

                        Accessible.role: Accessible.Button
                        Accessible.name: netItem.modelData.name + (netItem.modelData.connected ? ", 연결됨" : "")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Icon {
                                name: "wifi"
                                size: 16
                                color: netItem.modelData.signalStrength > 0.5 ? Theme.fg : Theme.muted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: netItem.modelData.name
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: netItem.modelData.connected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: text !== ""
                                    text: netItem.modelData.connected ? "연결됨 · 누르면 끊어요" : netItem.modelData.known ? "저장됨" : ""
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                }
                            }

                            Icon {
                                visible: netItem.secured
                                name: "lock"
                                size: 13
                                color: Theme.muted
                            }
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.chooseNetwork(netItem.modelData)
                        }
                    }

                    // Password for a secured network that isn't saved yet
                    RowLayout {
                        visible: root.pskNetwork === netItem.modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 4
                        Layout.bottomMargin: 4
                        spacing: 8

                        InputField {
                            id: psk
                            Layout.fillWidth: true
                            placeholder: "비밀번호"
                            password: true
                            onAccepted: connectButton.clicked()
                        }

                        ActionButton {
                            id: connectButton
                            text: "연결"
                            onClicked: {
                                if (psk.text.length > 0) {
                                    netItem.modelData.connectWithPsk(psk.text);
                                    psk.text = "";
                                    root.pskNetwork = null;
                                }
                            }
                        }
                    }
                }
            }

            // ---- Bluetooth devices ----
            Repeater {
                model: !root.wifi && ShellState.btEnabled ? root.devices.slice(0, 10) : []

                Rectangle {
                    id: devItem

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radiusMd
                    color: devMouse.containsMouse ? Theme.hover : devItem.modelData.connected ? Theme.raised : "transparent"

                    Accessible.role: Accessible.Button
                    Accessible.name: (devItem.modelData.name || devItem.modelData.address) + ", " + root.deviceStatus(devItem.modelData)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 10

                        Icon {
                            name: "bluetooth"
                            size: 16
                            color: devItem.modelData.connected ? Theme.fg : Theme.muted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: devItem.modelData.name || devItem.modelData.address
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: devItem.modelData.connected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.deviceStatus(devItem.modelData)
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }

                        IconButton {
                            visible: devItem.modelData.paired
                            implicitWidth: 26
                            implicitHeight: 26
                            icon: "trash"
                            iconSize: 13
                            iconColor: Theme.muted
                            label: "이 장치 지우기"
                            onClicked: devItem.modelData.forget()
                        }
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        anchors.rightMargin: devItem.modelData.paired ? 34 : 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.chooseDevice(devItem.modelData)
                    }
                }
            }

            Rectangle {
                visible: root.wifi
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            // nmtui handles hidden networks, VPNs and fixed addresses
            ActionButton {
                visible: root.wifi
                Layout.alignment: Qt.AlignRight
                variant: "ghost"
                implicitHeight: 28
                text: "고급 네트워크 설정 (nmtui)"
                onClicked: {
                    root.close();
                    ShellState.runInTerminal("nmtui");
                }
            }
        }
    }
}
