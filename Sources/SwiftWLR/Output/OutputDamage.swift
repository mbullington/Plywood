import Cwlroots

open class WLROutputDamage {
    let wlrOutputDamage: UnsafeMutablePointer<wlr_output_damage>

    public var current: PixmanRegion32 {
        get {
            return PixmanRegion32(&wlrOutputDamage.pointee.current)
        }
    }

    public init(output: WLROutput) {
        self.wlrOutputDamage = wlr_output_damage_create(output.wlrOutput)
    }

    deinit {
        wlr_output_damage_destroy(wlrOutputDamage)
    }

    public func addWhole() {
        wlr_output_damage_add_whole(wlrOutputDamage)
    }

    public func attachRender() -> (needsFrame: Bool, bufferDamage: PixmanRegion32) {
        var needsFrame: Bool = false
        let region = PixmanRegion32(position: (x: 0, y: 0), area: (width: 0, height: 0))

        wlr_output_damage_attach_render(wlrOutputDamage, &needsFrame, region.region)

        return (needsFrame: needsFrame, bufferDamage: region)
    }
}
