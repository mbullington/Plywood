import SwiftWayland
import SwiftWLR

class PlywoodCursor {
    enum Mode {
        case passthrough
        case move(PlywoodView, Point)
        case resize(PlywoodView, Point, Area, WLREdges)
    }

    let cursor: WLRCursor
    var mode: Mode = .passthrough
    private let state: PlywoodState

    var motionListener: WLListener<WLRPointer.MotionEvent>!
    var absoluteMotionListener: WLListener<WLRPointer.AbsoluteMotionEvent>!
    var buttonListener: WLListener<WLRPointer.ButtonEvent>!
    var axisListener: WLListener<WLRPointer.AxisEvent>!
    var frameListener: WLListener<WLRPointer>!

    init(_ cursor: WLRCursor, state: PlywoodState) {
        self.cursor = cursor
        self.state = state

        self.motionListener = cursor.onMotion.listen(onMotion)
        self.absoluteMotionListener =
            cursor.onAbsoluteMotion.listen(onAbsoluteMotion)
        self.buttonListener = cursor.onButton.listen(onButton)
        self.axisListener = cursor.onAxis.listen(onAxis)
        self.frameListener = cursor.onFrame.listen(onFrame)

        cursor.attach(outputLayout: state.outputLayout)
    }

    func processMotion(time: UInt32) {
        let seat = state.seat.seat
        let result = state.stage.findView(at: cursor.position)

        if result?.view == nil {
            state.cursorManager.setImage(of: cursor, to: "left_ptr")
        }

        if let surface = result?.surface {
            let coordinates = result!.coordinates
            let focusChanged =
                (seat.pointerState.focusedSurface != surface)

            seat.notifyPointerEnter(surface, at: coordinates)

            if !focusChanged {
                seat.notifyPointerMove(to: coordinates, time: time)
            }
        } else {
            seat.clearFocus()
        }
    }

    func onMotion(event: WLRPointer.MotionEvent) {
        cursor.move(by: event.delta, using: event.device)
        processMotion(time: event.timeInMilliseconds)
    }

    func onAbsoluteMotion(event: WLRPointer.AbsoluteMotionEvent) {
        cursor.move(to: event.normalizedPosition, using: event.device)
        processMotion(time: event.timeInMilliseconds)
    }

    func onButton(event: WLRPointer.ButtonEvent) {
        state.seat.seat.notifyPointerButton(
            event.button, state: event.state, time: event.timeInMilliseconds)

        guard event.state != .released else {
            mode = .passthrough
            return
        }

        guard let result = state.stage.findView(at: cursor.position) else {
            return
        }

        result.view.focus()
        state.stage.focusView(result.view)
    }

    func onAxis(event: WLRPointer.AxisEvent) {
        state.seat.seat.notifyPointerAxis(
            delta: event.delta, discreteDelta: event.discreteDelta,
            source: event.source, orientation: event.orientation,
            time: event.timeInMilliseconds
        )
    }

    func onFrame(_: WLRPointer) {
        state.seat.seat.notifyPointerFrame()
    }
}

