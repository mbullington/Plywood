import SwiftWayland
import SwiftWLR

class PlywoodOutput {
    let output: WLROutput
    private let state: PlywoodState

    var frameListener: WLListener<WLROutput>!
    var scaleListener: WLListener<WLROutput>!

    init(_ output: WLROutput, state: PlywoodState) {
        self.output = output
        self.state = state

        self.frameListener = output.onFrame.listen(onFrame)
        self.scaleListener = output.onScale.listen(onScale)
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

    func onScale(_: WLROutput) {
        state.stage.updateCrossAxis(height: output.effectiveResolution.height)
    }
}
