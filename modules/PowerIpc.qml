import Quickshell
import Quickshell.Io
import "." as Modules

IpcHandler {
    target: "power"

    function toggle(): void { Modules.IslandRegistry.togglePowerAll() }
    function open(): void { Modules.IslandRegistry.openPowerAll() }
    function close(): void { Modules.IslandRegistry.closePowerAll() }
}
