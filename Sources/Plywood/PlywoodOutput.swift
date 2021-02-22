import SwiftWayland
import SwiftWLR

class PlywoodOutput {
    let output: WLROutput
    private let state: PlywoodState

    var frameListener: WLListener<WLROutput>!

    init(_ output: WLROutput, state: PlywoodState) {
        self.output = output
        self.state = state

        self.frameListener = output.onFrame.listen(onFrame)
    }

    func configure() {
        // if (!output.modes.isEmpty) {
        //     let mode = output.modes.first
        //     output.setMode(mode)
        // }

        // Organizes from left to right, which for right now is pretty helpful
        // since all windows will be one row in the stage.
        state.outputLayout.insert(output)
        output.createGlobal()
    }

    func onFrame(_: WLROutput) {
        // Advance any animations.
        state.schedulerNextTick()

        let renderer = state.server.renderer

        guard output.attachRender() else {
            return
        }

        renderer.begin(resolution: output.effectiveResolution)
        renderer.clear(color: Color(0.3, 0.3, 0.3, 1.0))

        // Render stage.
        state.stage.render(output: output, screenOffsetX: 0, resolution: output.effectiveResolution)

        output.renderSoftwareCursors()

        renderer.end()
        output.commit()
    }
}
