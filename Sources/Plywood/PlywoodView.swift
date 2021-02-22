import SwiftWLR

/**
 * View abstraction we can use for XDG, XWayland, etc...
 */
protocol PlywoodView: AnyObject {
    var surface: WLRSurface { get }
    var position: PointStruct { get set }
    var area: Area { get set }
    // Area of the entire surface, i.e. without any box shadows, etc.
    var surfaceArea: Area { get }

    func forEachSurface(_ iterator: @escaping SurfaceIteratorCallback) -> Void
    func findSurface(at position: Point) -> (surface: WLRSurface, coordinates: Point)?

    func render(surface: WLRSurface, output: WLROutput, position: Position) -> Void

    func focus() -> Void
}
