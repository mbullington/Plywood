import SwiftWayland
import SwiftWLR

import SkiaKit

import Cplywood

class PlywoodOutput {
    let output: WLROutput
    private let state: PlywoodState

    var frameListener: WLListener<WLROutput>!

    private var surface: Surface?

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

    func getOrCreateSurface() -> Surface? {
        if surface != nil {
            return surface
        }

        let resolution = output.effectiveResolution
        let glInfo = plywood_get_gl_info(state.server.renderer.egl.display)

        guard let renderTarget = GRBackendRenderTarget.makeGL(
            width: resolution.width,
            height: resolution.height,
            samples: 0,
            // Needed for Skia.
            stencils: 0,
            fFBOID: glInfo.buffer
        ) else {
            return nil
        }

        surface = Surface.makeBackendRenderTarget(
            context: state.grContext,
            target: renderTarget
        )
        
        guard surface != nil else {
            return nil
        }

        plywood_gl_init()
        return surface
    }

    func onFrame(_: WLROutput) {
        // Advance any animations.
        state.schedulerNextTick()

        guard output.attachRender() else {
            return
        }

        // Render stage.
        guard let surface = getOrCreateSurface() else {
            state.logger.critical("Skipped frame due to corrupted Skia surface")
            output.commit()
            return
        }

        state.grContext.resetContext()
        
        let canvas = surface.canvas
        canvas.clear(color: Colors.darkGray)

        // Render stage.
        state.stage.render(output: output, canvas: canvas, screenOffsetX: 0, resolution: output.effectiveResolution)

        state.grContext.flush()
        output.renderSoftwareCursors()
        output.commit()
    }
}
