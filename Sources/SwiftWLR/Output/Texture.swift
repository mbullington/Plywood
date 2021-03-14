import Cwlroots

public class WLRTextureGLESAttributes {
    let wlrTexture: UnsafeMutablePointer<wlr_texture>
    let attribs: UnsafeMutablePointer<wlr_gles2_texture_attribs>

    public var target: CUnsignedInt {
        get {
            return attribs.pointee.target
        }
    }

    public var tex: CUnsignedInt {
        get {
            return attribs.pointee.tex
        }
    }

    public init(_ pointer: UnsafeMutablePointer<wlr_texture>) {
        self.wlrTexture = pointer

        self.attribs = UnsafeMutablePointer<wlr_gles2_texture_attribs>.allocate(capacity: 1)
        wlr_gles2_texture_get_attribs(self.wlrTexture, self.attribs)
    }

    deinit {
        self.attribs.deallocate()
    }
}

public class WLRTexture {
    let wlrTexture: UnsafeMutablePointer<wlr_texture>

    public var width: CUnsignedInt {
        get {
            return wlrTexture.pointee.width
        }
    }

    public var height: CUnsignedInt {
        get {
            return wlrTexture.pointee.height
        }
    }

    public var glesAttribs: WLRTextureGLESAttributes? {
        get {
            guard wlr_texture_is_gles2(self.wlrTexture) else {
                return nil
            }

            return WLRTextureGLESAttributes(self.wlrTexture)
        }
    }

    public init(_ pointer: UnsafeMutablePointer<wlr_texture>) {
        self.wlrTexture = pointer
    }
}
