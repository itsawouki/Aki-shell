import Quickshell
import Quickshell.Io
import "." as Modules

IpcHandler {
    target: "clipboard"

    function toggle(): void { Modules.IslandRegistry.toggleClipboardAll() }
    function open(): void { Modules.IslandRegistry.openClipboardAll() }
    function close(): void { Modules.IslandRegistry.closeClipboardAll() }
}
