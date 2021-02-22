import SwiftWayland
import Cwlroots

public class PixmanRegion32: RawPointerInitializable {
    public var region: UnsafeMutablePointer<pixman_region32_t>!

    public init(position: Position, area: Area) {
        region = UnsafeMutablePointer<pixman_region32_t>.allocate(capacity: 1)
        pixman_region32_init_rect(region, position.x, position.y, UInt32(area.width), UInt32(area.height))
    }

    required public init(_ pointer: UnsafeMutableRawPointer) {
        self.region = pointer.assumingMemoryBound(to: pixman_region32_t.self)
    }

    deinit {
        pixman_region32_fini(region)
    }
}