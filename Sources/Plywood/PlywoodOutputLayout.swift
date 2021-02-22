import SwiftWayland
import SwiftWLR

class PlywoodOutputLayout: WLROutputLayout {
    private let state: PlywoodState

    private var resolutions: [String: Area] = [:]
    var combinedResolution: Area = (width: 0, height: 0)

    private var modeListeners: [WLListener<WLROutput>] = []

    init(state: PlywoodState) {
        self.state = state

        super.init()
    }

    func insert(_ output: WLROutput) {
        // Actually add it to wlroots.
        automaticallyAdd(output)
        // Subscribe to mode changes so we can calculate the combined resolution.
        self.modeListeners.append(output.onMode.listen(onMode))

        computeResolution(output: output)
    }

    func computeResolution(output: WLROutput) {
        let resolution = output.effectiveResolution
        resolutions[output.name] = resolution

        // TODO: We can speed this up.
        combinedResolution.width = resolution.width
        combinedResolution.height = resolution.height
        for area in resolutions.values {
            if area.width < combinedResolution.width {
                combinedResolution.width = area.width
            }
            
            if area.height < combinedResolution.height {
                combinedResolution.height = area.height
            }
        }
    }

    // FIXME: Do we need to clean these up somehow?

    func onMode(output: WLROutput) {
        computeResolution(output: output)

        // Make sure we update the stage.
        state.stage.updateOutputMode()
    }
}