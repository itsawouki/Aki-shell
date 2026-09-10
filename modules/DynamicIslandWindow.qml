import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "." as Modules

PanelWindow {
    id: panelWindow

    required property var modelData
    screen: modelData

    property alias island: island

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
        item: island.anyOpen ? clickCatcher : island
    }

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "myshell-island"

    WlrLayershell.keyboardFocus: island.anyOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    onMonitorHasFullscreenChanged: {
        if (monitorHasFullscreen) island.closeAll()
    }

    Component.onCompleted: Modules.IslandRegistry.register(island)
    Component.onDestruction: Modules.IslandRegistry.unregister(island)

    Item {
        id: clickCatcher
        anchors.fill: parent
        visible: island.anyOpen

        MouseArea {
            anchors.fill: parent
            onClicked: island.closeAll()
        }
    }

    Modules.DynamicIsland {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }
}
