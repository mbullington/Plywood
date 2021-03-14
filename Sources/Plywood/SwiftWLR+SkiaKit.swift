import SkiaKit
import Cplywood

import class SwiftWLR.WaylandServer
import class SwiftWLR.WLRTexture

// FIXME
private var grContextCached: GRContext?

extension WaylandServer {
    public var grContext: GRContext? {
        get {
            if (grContextCached != nil) {
                return grContextCached
            }

            // As per this ref: https://skia.org/user/api/skcanvas_creation
            guard let glInterfacePtr = plywood_gles_interface(nil) else {
                return nil
            }
            let glInterface = GRGLInterface(handle: glInterfacePtr)

            guard let context = GRContext.makeGL(interface: glInterface) else {
                return nil
            }

            grContextCached = context
            return context
        }
    }
}

// Just got this from grepping through /usr/include/GLES2
private let GL_RGBA: UInt32 = 0x1908
private let GL_BGRA_EXT: UInt32 = 0x80E1

extension WLRTexture {
    func toImage(_ context: GRContext) -> Image? {
        guard let attribs = self.glesAttribs else {
            return nil
        }

        // This is managed by Skia so we can allocate it safely.
        let glInfo = UnsafeMutablePointer<GRGLTextureInfo>.allocate(capacity: 1)
            
        glInfo.pointee.fTarget = attribs.target
        glInfo.pointee.fID = attribs.tex
        glInfo.pointee.fFormat = GL_RGBA

        guard let texture: GRBackendTexture = GRBackendTexture.makeGL(
            width: CInt(self.width),
            height: CInt(self.height),
            mipmapped: false,
            glInfo: &glInfo.pointee
        ) else {
            return nil
        } 

        guard texture.valid else {
            return nil
        }

        return Image.fromTexture(
            context: context,
            texture: texture
        )
    }
}
