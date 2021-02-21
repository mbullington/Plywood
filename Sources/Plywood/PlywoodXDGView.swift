import SwiftWayland
import SwiftWLR

class PlywoodXDGView: PlywoodView {
    let xdgSurface: WLRXDGSurface
    private let state: PlywoodState

    var surface: WLRSurface {
        get { return xdgSurface.surface }
    }

    var geometryBox: WLRBox {
        get { return xdgSurface.geometryBox }
    }

    var mapListener: WLListener<WLRXDGSurface>!
    var unmapListener: WLListener<WLRXDGSurface>!
    var destroyListener: WLListener<WLRXDGSurface>!

    var moveRequestListener: WLListener<WLRXDGTopLevel.MoveRequestEvent>?
    var resizeRequestListener: WLListener<WLRXDGTopLevel.ResizeRequestEvent>?

    var position: Point
    var isMapped: Bool = false

    init(_ xdgSurface: WLRXDGSurface, state: PlywoodState) {
        self.xdgSurface = xdgSurface
        self.state = state

        self.position = (x: 0, y: 0)

        self.mapListener = xdgSurface.onMap.listen(onMap)
        self.unmapListener = xdgSurface.onUnmap.listen(onUnmap)
        self.destroyListener = xdgSurface.onDestroy.listen(onDestroy)

        guard case let .topLevel(topLevel) = xdgSurface.role else {
            return
        }

        self.moveRequestListener =
            topLevel.onMoveRequest.listen(onMoveRequest)
        self.resizeRequestListener =
            topLevel.onResizeRequest.listen(onResizeRequest)
    }

    public func forEachSurface(_ iterator: @escaping SurfaceIteratorCallback) {
        xdgSurface.forEachSurface(iterator)
    }

    func onMap(_: WLRXDGSurface) {
        isMapped = true
        focus()
    }

    func onUnmap(_: WLRXDGSurface) {
        isMapped = false
    }

    func onDestroy(_: WLRXDGSurface) {
        state.stage.remove(self)
    }

    func onMoveRequest(event: WLRXDGTopLevel.MoveRequestEvent) {
        state.cursor.beginMove(view: self)
    }

    func onResizeRequest(event: WLRXDGTopLevel.ResizeRequestEvent) {
        state.cursor.beginResize(view: self, edges: event.edges)
    }

    func findSurface(
        at position: Point
    ) -> (surface: WLRSurface, coordinates: Point)? {
        let viewPosition = position - self.position
        // let surfaceState = surface.surface.current

        return xdgSurface.findSurface(at: viewPosition)
    }

    func render(surface: WLRSurface, output: WLROutput, position: Position) {
        guard let texture = surface.fetchTexture() else {
            return
        }

        let outputCoordinates =
            state.outputLayout.outputCoordinates(of: output) +
            self.position +
            position

        let scaledOutputCoordinates = outputCoordinates * Double(output.scale)
        let scaledOutputArea = surface.current.area * Double(output.scale)

        let box = WLRBox(
            position: Position(
                x: Int32(scaledOutputCoordinates.x),
                y: Int32(scaledOutputCoordinates.y)
            ),
            area: scaledOutputArea
        )

        let matrix = box.project(
            transform: surface.current.transform,
            rotation: 0,
            projection: output.transformMatrix
        )

        let renderer = state.server.renderer
        renderer.render(texture: texture, with: matrix, alpha: 1)

        surface.sendFrameDone()
    }

    func focus() {
        let seat = state.seat.seat
        let previousSurface = seat.keyboardState.focusedSurface

        guard previousSurface != surface else {
            return
        }

        if let previousSurface = previousSurface {
            let previousXDGSurface = WLRXDGSurface(previousSurface)
            previousXDGSurface.activated = false
        }

        state.stage.focus(self)
        xdgSurface.activated = true

        seat.notifyKeyboardEnter(surface, keyboard: seat.keyboard)
    }

    func setSize(_ area: Area) {
        xdgSurface.setSize(area)
    }
}
