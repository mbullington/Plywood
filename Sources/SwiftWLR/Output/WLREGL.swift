import Cwlroots

public class WLREGL {
    let egl: UnsafeMutablePointer<wlr_egl>

    public var context: EGLContext? {
        get {
            return egl.pointee.context
        }
    }

    public var display: EGLDisplay {
        get {
            return egl.pointee.display
        }
    }

    public init(_ pointer: UnsafeMutablePointer<wlr_egl>) {
        self.egl = pointer
    }
}
