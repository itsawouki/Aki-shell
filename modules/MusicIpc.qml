import Quickshell
import Quickshell.Io
import "." as Modules

// qs ipc call music toggle|open|close
IpcHandler {
    target: "music"

    function toggle(): void { Modules.IslandRegistry.toggleMusicAll() }
    function open(): void { Modules.IslandRegistry.openMusicAll() }
    function close(): void { Modules.IslandRegistry.closeMusicAll() }
}
