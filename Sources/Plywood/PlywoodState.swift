import SwiftWayland
import SwiftWLR

import Logging

final class PlywoodState {
    let logger = Logger(label: "Plywood")

    let server: WaylandServer

    var outputs: [PlywoodOutput]
    let outputLayout: WLROutputLayout

    var stage: PlywoodStage!

    let cursorManager: WLRXCursorManager

    var seat: PlywoodSeat!
    var cursor: PlywoodCursor!
    var keyboards: [PlywoodKeyboard]

    var newOutputListener: WLListener<WLROutput>!
    var newInputListener: WLListener<SomeWLRInputDevice>!
    var newXDGSurfaceListener: WLListener<WLRXDGSurface>!

    let xdgShell: WLRXDGShell

    init(for server: WaylandServer) {
        self.server = server

        // Setup protocol implementations.
        self.xdgShell = WLRXDGShell(display: server.display)

        self.outputs = []
        self.outputLayout = WLROutputLayout()

        self.cursorManager = WLRXCursorManager(name: nil, size: 24)
        self.cursorManager.load(scale: 1)

        self.keyboards = []

        self.stage = PlywoodStage(state: self)

        self.seat = PlywoodSeat(
            WLRSeat("seat0", for: server.display), state: self)

        self.cursor = PlywoodCursor(WLRCursor(), state: self)

        self.newOutputListener = server.onNewOutput.listen(onNewOutput)
        self.newInputListener = server.onNewInput.listen(onNewInput)
        self.newXDGSurfaceListener = xdgShell.onNewXDGSurface.listen(onNewXDGSurface)
    }

    func onNewOutput(inner: WLROutput) {
        let output = PlywoodOutput(inner, state: self)
        output.configure()

        outputs.append(output)
    }

    func onNewInput(device: SomeWLRInputDevice) {
        switch device {
        case .pointer(let pointer):
            onNewPointer(pointer)
        case .keyboard(let keyboard):
            onNewKeyboard(keyboard)
        }

        var capabilities: WLSeatCapabilities = [.pointer]

        if !keyboards.isEmpty {
            capabilities.insert(.keyboard)
        }

        seat.seat.capabilities = capabilities
    }

    func onNewXDGSurface(surface: WLRXDGSurface) {
        guard case .topLevel = surface.role else {
            return
        }

        let view = PlywoodXDGView(surface, state: self)
        state.stage.insert(view)
    }

    func onNewPointer(_ pointer: WLRInputDevice<WLRPointer>) {
        cursor.cursor.attach(pointer: pointer)
    }

    func onNewKeyboard(_ keyboard: WLRInputDevice<WLRKeyboard>) {
        let keyboard = PlywoodKeyboard(keyboard, state: self)
        keyboards.append(keyboard)
    }
}
