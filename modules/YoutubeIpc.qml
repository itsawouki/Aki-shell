import Quickshell
import Quickshell.Io
import "." as Modules

IpcHandler {
    target: "youtube"

    function toggle(): void { Modules.IslandRegistry.toggleYoutubeAll() }
    function open(): void { Modules.IslandRegistry.openYoutubeAll() }
    function close(): void { Modules.IslandRegistry.closeYoutubeAll() }
}
