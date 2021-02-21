import SwiftWLR

/**
 * View abstraction we can use for XDG, XWayland, etc...
 */
protocol PlywoodView: AnyObject {
    var surface: WLRSurface { get }
    var position: Point { get set }
    var geometryBox: WLRBox { get }

    func forEachSurface(_ iterator: @escaping SurfaceIteratorCallback) -> Void
    func findSurface(at position: Point) -> (surface: WLRSurface, coordinates: Point)?

    func render(surface: WLRSurface, output: WLROutput, position: Position) -> Void

    func setSize(_ area: Area) -> Void

    func focus() -> Void
}
