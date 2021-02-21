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

    func beginMove(view: PlywoodView) {
        let seat = state.seat.seat
        let focusedSurface = seat.keyboardState.focusedSurface

        guard view.surface == focusedSurface else {
            // Ignore interactive move requests from unfocused clients.
            return
        }

        let grabInitialPosition = cursor.position - view.position
        mode = .move(view, grabInitialPosition)
    }

    func beginResize(view: PlywoodView, edges: WLREdges) {        
        let seat = state.seat.seat
        let focusedSurface = seat.keyboardState.focusedSurface

        guard view.surface == focusedSurface else {
            // Ignore interactive resize requests from unfocused clients.
            return
        }

        let geometryBox = view.geometryBox
        let grabInitialPosition = cursor.position + geometryBox.position
        mode = .resize(view, grabInitialPosition, geometryBox.area, edges)
    }

    func processViewMove(mode: PlywoodCursor.Mode, time: UInt32) {
        return
        // guard case let .move(view, initialGrabPosition) = mode else {
        //     return
        // }

        // view.position = cursor.position - initialGrabPosition
    }

    func processViewResize(mode: PlywoodCursor.Mode, time: UInt32) {
        guard case let .resize(
            view, initialGrabPosition, area, edges) = mode else {
            return
        }

        let positionDelta = cursor.position - initialGrabPosition
        var newPosition = view.position
        var newArea = area

        if edges.contains(.top) {
            newPosition.y = initialGrabPosition.y + positionDelta.y
            newArea.height -= Int32(positionDelta.y)

            if newArea.height < 1 {
                newPosition.y += Double(newArea.height)
            }
        } else if edges.contains(.bottom) {
            newArea.height += Int32(positionDelta.y)
        }

        if edges.contains(.left) {
            newPosition.x = initialGrabPosition.x + positionDelta.x
            newArea.width -= Int32(positionDelta.x)

            if newArea.width < 1 {
                newPosition.x += Double(newArea.width)
            }
        } else if edges.contains(.right) {
            newArea.width += Int32(positionDelta.x)
        }

        view.position = newPosition
        view.setSize(newArea)
    }

    func processMotion(time: UInt32) {
        let cursorMode = state.cursor.mode

        switch cursorMode {
        case .passthrough:
            break
        case .move:
            processViewMove(mode: cursorMode, time: time)
            return
        case .resize:
            processViewResize(mode: cursorMode, time: time)
            return
        }

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

