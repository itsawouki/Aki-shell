import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "." as Modules

PanelWindow {
    id: panelWindow

    required property var modelData
    screen: modelData

    property alias panel: networkPanel

    property var hyprMonitor: Hyprland.monitorFor(screen)
    property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false

    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: !monitorHasFullscreen

    mask: Region {
        item: networkPanel.expanded ? clickCatcher : networkPanel
    }

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "myshell-network-notch"

    WlrLayershell.keyboardFocus: networkPanel.expanded
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    onMonitorHasFullscreenChanged: {
        if (monitorHasFullscreen) networkPanel.close()
    }

    Component.onCompleted: Modules.NetworkNotchRegistry.register(networkPanel)
    Component.onDestruction: Modules.NetworkNotchRegistry.unregister(networkPanel)

    Item {
        id: clickCatcher
        anchors.fill: parent
        visible: networkPanel.expanded

        MouseArea {
            anchors.fill: parent
            onClicked: networkPanel.close()
        }
    }

    NetworkPanel {
        id: networkPanel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
