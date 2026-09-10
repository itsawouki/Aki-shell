import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "." as Modules

PanelWindow {
    id: panelWindow

    required property var modelData
    screen: modelData

    property alias panel: settingsPanel

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
        item: settingsPanel.expanded ? clickCatcher : nullMask
    }

    // Invisible passthrough item when collapsed
    Item { id: nullMask; width: 0; height: 0; visible: false }

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "myshell-settings"

    WlrLayershell.keyboardFocus: settingsPanel.expanded
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    onMonitorHasFullscreenChanged: {
        if (monitorHasFullscreen) settingsPanel.close()
    }

    Component.onCompleted: Modules.SettingsNotchRegistry.register(settingsPanel)
    Component.onDestruction: Modules.SettingsNotchRegistry.unregister(settingsPanel)

    Item {
        id: clickCatcher
        anchors.fill: parent
        visible: settingsPanel.expanded

        MouseArea {
            anchors.fill: parent
            onClicked: settingsPanel.close()
        }
    }

    SettingsPanel {
        id: settingsPanel
        anchors.centerIn: parent
    }
}
