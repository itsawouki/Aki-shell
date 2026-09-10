import Quickshell
import Quickshell.Io
import "." as Modules

// qs ipc call network toggle|open|close
IpcHandler {
    target: "network"

    function toggle(): void { Modules.NetworkNotchRegistry.toggleAll() }
    function open(): void { Modules.NetworkNotchRegistry.openAll() }
    function close(): void { Modules.NetworkNotchRegistry.closeAll() }
}
