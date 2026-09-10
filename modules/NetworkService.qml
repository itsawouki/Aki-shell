pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Talks to NetworkManager through `nmcli` — there's no official Quickshell
// NetworkManager binding yet (unlike Pipewire/Mpris/UPower), so this polls
// device status on a timer and parses nmcli's terse (-t) output. Wi-Fi
// scans and VPN profile lists are refreshed on demand (e.g. when the
// panel opens) rather than continuously, since scanning is slow-ish.
Singleton {
    id: service

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string wifiSSID: ""
    property string wifiDevice: ""

    property bool ethernetConnected: false
    property string ethernetDevice: ""
    property string ethernetConnectionName: ""

    property bool scanning: false
    property var accessPoints: []        // [{ ssid, signal, secured, active }]

    property var vpnProfiles: []         // [{ name, type }]
    property var activeConnectionNames: []
    readonly property var vpnConnections: vpnProfiles.map(function (p) {
        return { name: p.name, active: activeConnectionNames.indexOf(p.name) !== -1 }
    })

    function refreshDevices() { deviceStatusProc.running = true }
    function refreshVpn() {
        vpnProfilesProc.running = true
        activeConnectionsProc.running = true
    }
    function scanWifi() {
        scanning = true
        wifiScanProc.running = true
    }

    function toggleWifiRadio() {
        radioToggleProc.command = ["nmcli", "radio", "wifi", service.wifiEnabled ? "off" : "on"]
        radioToggleProc.running = true
    }

    function connectEthernet() {
        if (!ethernetDevice) return
        ethernetActionProc.command = ["nmcli", "device", "connect", ethernetDevice]
        ethernetActionProc.running = true
    }
    function disconnectEthernet() {
        if (!ethernetDevice) return
        ethernetActionProc.command = ["nmcli", "device", "disconnect", ethernetDevice]
        ethernetActionProc.running = true
    }

    function connectWifi(ssid, password) {
        wifiConnectProc.command = password.length > 0
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "device", "wifi", "connect", ssid]
        wifiConnectProc.running = true
    }
    function disconnectWifi() {
        if (!wifiDevice) return
        wifiActionProc.command = ["nmcli", "device", "disconnect", wifiDevice]
        wifiActionProc.running = true
    }

    function connectVpn(name) {
        vpnActionProc.command = ["nmcli", "connection", "up", name]
        vpnActionProc.running = true
    }
    function disconnectVpn(name) {
        vpnActionProc.command = ["nmcli", "connection", "down", name]
        vpnActionProc.running = true
    }

    function openConnectionEditor() {
        editorProc.running = true
    }

    function parseDeviceStatus(text) {
        const lines = text.split("\n").filter(function (l) { return l.length > 0 })
        let eth = null
        let wifi = null
        for (const line of lines) {
            const parts = line.split(":")
            const device = parts[0]
            const type = parts[1]
            const state = parts[2]
            const connection = parts.slice(3).join(":")
            if (type === "ethernet" && !eth) eth = { device: device, state: state, connection: connection }
            if (type === "wifi" && !wifi) wifi = { device: device, state: state, connection: connection }
        }
        if (eth) {
            service.ethernetDevice = eth.device
            service.ethernetConnected = eth.state === "connected"
            service.ethernetConnectionName = eth.connection
        } else {
            service.ethernetDevice = ""
            service.ethernetConnected = false
            service.ethernetConnectionName = ""
        }
        if (wifi) {
            service.wifiDevice = wifi.device
            service.wifiConnected = wifi.state === "connected"
            service.wifiSSID = wifi.state === "connected" ? wifi.connection : ""
            service.wifiEnabled = wifi.state !== "unavailable"
        } else {
            service.wifiDevice = ""
            service.wifiConnected = false
            service.wifiSSID = ""
            service.wifiEnabled = false
        }
    }

    function parseWifiList(text) {
        const lines = text.split("\n").filter(function (l) { return l.length > 0 })
        const seen = ({})
        const list = []
        for (const line of lines) {
            const parts = line.split(":")
            const inUse = parts[0] === "*"
            const ssid = parts[1]
            const signal = parseInt(parts[2] || "0", 10)
            const security = parts.slice(3).join(":")
            if (!ssid || seen[ssid]) continue
            seen[ssid] = true
            list.push({ ssid: ssid, signal: signal, secured: security.length > 0, active: inUse })
        }
        list.sort(function (a, b) { return b.signal - a.signal })
        service.accessPoints = list
        service.scanning = false
    }

    function parseVpnProfiles(text) {
        const lines = text.split("\n").filter(function (l) { return l.length > 0 })
        const list = []
        for (const line of lines) {
            const parts = line.split(":")
            const name = parts[0]
            const type = parts.slice(1).join(":")
            if (type === "vpn" || type === "wireguard") list.push({ name: name, type: type })
        }
        service.vpnProfiles = list
    }

    function parseActiveConnections(text) {
        service.activeConnectionNames = text.split("\n").filter(function (l) { return l.length > 0 })
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.refreshDevices()
    }

    Process {
        id: deviceStatusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: service.parseDeviceStatus(this.text)
        }
    }

    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: service.parseWifiList(this.text)
        }
    }

    Process {
        id: vpnProfilesProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: service.parseVpnProfiles(this.text)
        }
    }

    Process {
        id: activeConnectionsProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: service.parseActiveConnections(this.text)
        }
    }

    Process { id: radioToggleProc; onExited: service.refreshDevices() }
    Process { id: ethernetActionProc; onExited: service.refreshDevices() }
    Process { id: wifiActionProc; onExited: service.refreshDevices() }
    Process {
        id: wifiConnectProc
        onExited: {
            service.refreshDevices()
            service.scanWifi()
        }
    }
    Process { id: vpnActionProc; onExited: service.refreshVpn() }
    Process { id: editorProc; command: ["nm-connection-editor"] }
}
