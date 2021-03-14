import SwiftWayland
import SwiftWLR

import class SkiaKit.Canvas
import class SkiaKit.Image
import struct SkiaKit.Rect

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

    var commitListener: WLListener<WLRSurface>!

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
        if !isMapped {
            // Remove reference count from "unmapped" array.
            state.unmappedXDGViews.removeAnyObject(self)
            // Add to stage.
            state.stage.insert(self)
        }

        isMapped = true

        // self.commitListener = xdgSurface.surface.onCommit.listen(onCommit)

        focus()
        state.stage.focusView(self)
    }

    func onUnmap(_: WLRXDGSurface) {
        isMapped = false
    }

    func onDestroy(_: WLRXDGSurface) {
        state.stage.remove(self)
    }

    func onCommit(_: WLRSurface) {
        // let area = self.area
        // // If we have unexpected change in size, make sure to reflow.
        // if area != cachedArea {
        //     cachedArea = area
        //     state.stage.reflowView(self)
        // }
    }

    func findSurface(
        at position: Point
    ) -> (surface: WLRSurface, coordinates: Point)? {
        let viewPosition = position - self.position.value
        // let surfaceState = surface.surface.current

        return xdgSurface.findSurface(at: viewPosition)
    }

    func render(surface: WLRSurface, canvas: Canvas, position: Position) {
        guard let texture = surface.fetchTexture() else {
            return
        }

        guard let image: Image = texture.toImage(state.grContext) else {
            return
        }

        let coords = self.position.value + position
        let area = surface.current.area 

        canvas.drawImage(
            image,
            SkiaKit.Rect(
                x: Float(coords.x),
                y: Float(coords.y),
                width: Float(area.width),
                height: Float(area.height)
            )
        )

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
