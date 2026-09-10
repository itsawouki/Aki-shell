import Quickshell
import Quickshell.Io
import "." as Modules

// qs ipc call settings toggle|open|close
IpcHandler {
    target: "settings"

    function toggle(): void { Modules.SettingsNotchRegistry.toggleAll() }
    function open(): void { Modules.SettingsNotchRegistry.openAll() }
    function close(): void { Modules.SettingsNotchRegistry.closeAll() }
}
