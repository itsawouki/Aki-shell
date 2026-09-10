import Quickshell
import Quickshell.Io
import "." as Modules

// qs ipc call audio toggle|open|close
IpcHandler {
    target: "audio"

    function toggle(): void { Modules.AudioNotchRegistry.toggleAll() }
    function open(): void { Modules.AudioNotchRegistry.openAll() }
    function close(): void { Modules.AudioNotchRegistry.closeAll() }
}
