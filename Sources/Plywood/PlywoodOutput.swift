import SwiftWayland
import SwiftWLR

class PlywoodOutput {
    let output: WLROutput
    private let state: PlywoodState

    var frameListener: WLListener<WLROutput>!
    var modeListener: WLListener<WLROutput>!

    init(_ output: WLROutput, state: PlywoodState) {
        self.output = output
        self.state = state

        self.frameListener = output.onFrame.listen(onFrame)
        self.modeListener = output.onMode.listen(onMode)
    }

    func configure() {
        // if (!output.modes.isEmpty) {
        //     let mode = output.modes.first
        //     output.setMode(mode)
        // }

        state.outputLayout.automaticallyAdd(output)
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

    func onMode(_: WLROutput) {
        state.stage.updateCrossAxis(height: output.effectiveResolution.height)
    }
}
