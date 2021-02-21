// TODO: I suppose that xkb-related things should be placed in a separate
// module.

import Cwlroots

public class XKBContext {
    let xkbContext: OpaquePointer

    public init() {
        self.xkbContext = xkb_context_new(XKB_CONTEXT_NO_FLAGS)
    }

    deinit {
        xkb_context_unref(xkbContext)
    }
}

public class XKBKeymap {
    let xkbKeymap: OpaquePointer

    public init(_ pointer: OpaquePointer) {
        self.xkbKeymap = pointer
    }

    public init(context: XKBContext) {
        var xkbRuleNames = xkb_rule_names()

        self.xkbKeymap = xkb_keymap_new_from_names(
            context.xkbContext,
            &xkbRuleNames,
            XKB_KEYMAP_COMPILE_NO_FLAGS
        )
    }

    deinit {
        xkb_keymap_unref(xkbKeymap)
    }
}

public class XKBState {
    let xkbState: OpaquePointer

    public init(_ pointer: OpaquePointer) {
        self.xkbState = pointer
    }

    public func getOneSym(keyCode: UInt32) -> UInt32 {
        return xkb_state_key_get_one_sym(xkbState, keyCode)
    }

    public func getSyms(keyCode: UInt32) -> [UInt32] {
        let syms = UnsafeMutablePointer<UnsafePointer<xkb_keysym_t>?>.allocate(capacity: 1)
        defer {
            syms.deallocate()
        }

        let length = xkb_state_key_get_syms(xkbState, keyCode, syms)

        var symsArr: [UInt32] = []
        for i in 0..<length {
            symsArr.append(syms[Int(i)]!.pointee)
        }

        return symsArr
    }
}