import Quickshell
import Quickshell.Io
import "." as Modules

IpcHandler {
    target: "island"

    function toggle(): void { Modules.IslandRegistry.toggleAll() }
    function open(): void { Modules.IslandRegistry.openAll() }
    function close(): void { Modules.IslandRegistry.closeAll() }
    function toggleMovies(): void { Modules.IslandRegistry.toggleMoviesAll() }
    function toggleYoutube(): void { Modules.IslandRegistry.toggleYoutubeAll() }
    function toggleClipboard(): void { Modules.IslandRegistry.toggleClipboardAll() }

  }
