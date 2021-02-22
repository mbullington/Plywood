import SwiftWayland
import SwiftWLR

class PlywoodXDGView: PlywoodView {
    let xdgSurface: WLRXDGSurface
    private let state: PlywoodState

    var surface: WLRSurface {
        get { return xdgSurface.surface }
    }

    // Use cached area to prevent un-needed reflows.
    private var cachedArea: Area!
    var area: Area {
        get { return xdgSurface.geometryBox.area }
        set(val) {
            cachedArea = val
            xdgSurface.setSize(val)
        }
    }

    var surfaceArea: Area {
        get { return xdgSurface.surface.current.area }
    }

    var mapListener: WLListener<WLRXDGSurface>!
    var unmapListener: WLListener<WLRXDGSurface>!
    var destroyListener: WLListener<WLRXDGSurface>!

    var position: PointStruct
    private var targetArea: Area?

    var isMapped: Bool = false

    init(_ xdgSurface: WLRXDGSurface, state: PlywoodState) {
        self.xdgSurface = xdgSurface
        self.state = state

        self.position = PointStruct(value: (x: 0, y: 0))
        self.cachedArea = self.area

        self.mapListener = xdgSurface.onMap.listen(onMap)
        self.unmapListener = xdgSurface.onUnmap.listen(onUnmap)
        self.destroyListener = xdgSurface.onDestroy.listen(onDestroy)
    }

    public func forEachSurface(_ iterator: @escaping SurfaceIteratorCallback) {
        xdgSurface.forEachSurface(iterator)
    }

    func onMap(_: WLRXDGSurface) {
        isMapped = true

        let area = self.area
        if area != cachedArea {
            cachedArea = area
            state.stage.reflowView(self)
        }

        focus()
    }

    func onUnmap(_: WLRXDGSurface) {
        isMapped = false
    }

    func onDestroy(_: WLRXDGSurface) {
        state.stage.remove(self)
    }

    func findSurface(
        at position: Point
    ) -> (surface: WLRSurface, coordinates: Point)? {
        let viewPosition = position - self.position.value
        // let surfaceState = surface.surface.current

        return xdgSurface.findSurface(at: viewPosition)
    }

    func render(surface: WLRSurface, output: WLROutput, position: Position) {
        guard let texture = surface.fetchTexture() else {
            return
        }

        let outputCoordinates =
            state.outputLayout.outputCoordinates(of: output) +
            self.position.value +
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

        xdgSurface.activated = true

        seat.notifyKeyboardEnter(surface, keyboard: seat.keyboard)
    }
}
