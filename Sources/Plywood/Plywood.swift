import SwiftWayland
import SwiftWLR

import TweenKit

import Foundation
import Logging

typealias Seconds = Double

final class PlywoodState {
    let logger = Logger(label: "Plywood")

    let server: WaylandServer

    var outputs: [PlywoodOutput]
    var outputLayout: PlywoodOutputLayout!

    var stage: PlywoodStage!
    // XDG Views that do exist, but have not created a surface yet to map.
    //
    // Really just so ARC won't clean these classes up.
    var unmappedXDGViews: [PlywoodXDGView] = []

    let scheduler = ActionScheduler() 
    private var schedulerLastTime: Seconds = -1

    let cursorManager: WLRXCursorManager

    // TODO: Is multiseat used heavily in accessibility?
    // Otherwise, don't see a huge compelling need to support it.
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

        self.cursorManager = WLRXCursorManager(name: nil, size: 24)
        self.cursorManager.load(scale: 1)

        self.keyboards = []

        self.outputLayout = PlywoodOutputLayout(state: self)
        self.stage = PlywoodStage(state: self)

        self.seat = PlywoodSeat(
            WLRSeat("seat0", for: server.display), state: self)

        self.cursor = PlywoodCursor(WLRCursor(), state: self)

        self.newOutputListener = server.onNewOutput.listen(onNewOutput)
        self.newInputListener = server.onNewInput.listen(onNewInput)
        self.newXDGSurfaceListener = xdgShell.onNewXDGSurface.listen(onNewXDGSurface)
    }

    // Keep track of time for the scheduler so we can run this easily from each output
    // on request frame.
    func schedulerNextTick() {
        if !scheduler.started {
            schedulerLastTime = -1
            return
        }

        let seconds = Date().timeIntervalSince1970

        if schedulerLastTime == -1 {
            schedulerLastTime = seconds
            scheduler.step(dt: 0)
            return
        }

        scheduler.step(dt: seconds - schedulerLastTime)
        schedulerLastTime = seconds
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
        // Removed when the map event is first fired.
        unmappedXDGViews.append(view)
    }

    func onNewPointer(_ pointer: WLRInputDevice<WLRPointer>) {
        cursor.cursor.attach(pointer: pointer)
    }

    func onNewKeyboard(_ keyboard: WLRInputDevice<WLRKeyboard>) {
        let keyboard = PlywoodKeyboard(keyboard, state: self)
        keyboards.append(keyboard)
    }
}
