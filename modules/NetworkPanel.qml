import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "." as Modules // needed for the NetworkService singleton below

Rectangle {
    id: panel

    property bool expanded: false

    property int panelWidth: 320
    property int panelHeight: 480

    function open() { expanded = true }
    function close() { expanded = false }
    function toggle() { expanded = !expanded }

    width: expanded ? panelWidth : 0
    height: panelHeight
    color: "#171717"
    clip: true
    antialiasing: true

    radius: 26
    topLeftRadius: radius
    bottomLeftRadius: radius
    topRightRadius: 0
    bottomRightRadius: 0

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.55
        shadowBlur: 1
        shadowHorizontalOffset: -3
    }

    Behavior on width {
        NumberAnimation { duration: 260; easing.type: Easing.OutExpo }
    }

    focus: true
    Keys.onEscapePressed: panel.close()

    onExpandedChanged: {
        if (expanded) {
            focusRetry.attempts = 0
            focusRetry.start()
            Modules.NetworkService.refreshDevices()
            Modules.NetworkService.refreshVpn()
            Modules.NetworkService.scanWifi()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            panel.forceActiveFocus()
            attempts++
            if (panel.activeFocus || attempts > 15) stop()
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 18
        opacity: panel.expanded ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            Text {
                text: "Network"
                color: "white"
                font.pixelSize: 15
                font.weight: Font.ExtraBold
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: sectionsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: sectionsColumn
                    width: parent.width
                    spacing: 20

                    // --- Ethernet ---------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "ETHERNET"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 12
                            color: Qt.rgba(1, 1, 1, 0.05)

RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 10

    ColumnLayout {
        spacing: 1
        Text {
            text: Modules.NetworkService.ethernetDevice
                ? (Modules.NetworkService.ethernetConnected ? "Connected" : "Disconnected")
                : "No device"
            color: "white"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        Text {
            visible: Modules.NetworkService.ethernetConnected
            text: Modules.NetworkService.ethernetConnectionName
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    Item { Layout.fillWidth: true }

    ToggleSwitch {
        checked: Modules.NetworkService.ethernetConnected
        onToggled: checked
            ? Modules.NetworkService.disconnectEthernet()
            : Modules.NetworkService.connectEthernet()
    }
}
                        }
                    }

                    // --- Wi-Fi -------------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "WI-FI"
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: Modules.NetworkService.wifiEnabled
                                text: Modules.NetworkService.scanning ? "Scanning\u2026" : "Rescan"
                                color: Qt.rgba(1, 1, 1, 0.45)
                                font.pixelSize: 10

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Modules.NetworkService.scanWifi()
                                }
                            }
                            ToggleSwitch {
                                Layout.leftMargin: 8
                                checked: Modules.NetworkService.wifiEnabled
                                onToggled: Modules.NetworkService.toggleWifiRadio()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            visible: Modules.NetworkService.wifiEnabled

                            Repeater {
                                model: Modules.NetworkService.accessPoints
                                delegate: WifiNetworkRow {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    ssid: modelData.ssid
                                    signalStrength: modelData.signal
                                    secured: modelData.secured
                                    active: modelData.active
                                    onConnectRequested: password => Modules.NetworkService.connectWifi(ssid, password)
                                    onDisconnectRequested: Modules.NetworkService.disconnectWifi()
                                }
                            }

                            Text {
                                visible: Modules.NetworkService.accessPoints.length === 0
                                text: Modules.NetworkService.scanning ? "Scanning\u2026" : "No networks found"
                                color: Qt.rgba(1, 1, 1, 0.35)
                                font.pixelSize: 11
                            }
                        }
                    }

                    // --- VPN ----------------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: Modules.NetworkService.vpnConnections.length > 0

                        Text {
                            text: "VPN"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }

                        Repeater {
                            model: Modules.NetworkService.vpnConnections
                            delegate: VpnConnectionRow {
                                required property var modelData
                                Layout.fillWidth: true
                                label: modelData.name
                                active: modelData.active
                                onClicked: modelData.active
                                    ? Modules.NetworkService.disconnectVpn(modelData.name)
                                    : Modules.NetworkService.connectVpn(modelData.name)
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                color: editArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.06)
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "\u{2699}"; font.pixelSize: 13; opacity: 0.85 }
                    Text {
                        text: "Edit Connections"
                        color: "white"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: editArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Modules.NetworkService.openConnectionEditor()
                }
            }
        }
    }
}
