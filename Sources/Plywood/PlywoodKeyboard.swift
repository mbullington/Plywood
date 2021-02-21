import SwiftWayland
import SwiftWLR

enum PWKeyboardModifier {
    case command
}

enum PWKeyboardModifierState {
    case single
    case multiple
}

class PlywoodKeyboard {
    let device: WLRInputDevice<WLRKeyboard>

    var keyboard: WLRKeyboard {
        get {
            return device.keyboard
        }
    }

    private let state: PlywoodState

    var modifiersListener: WLListener<WLRKeyboard>!
    var keyListener: WLListener<WLRKeyboardKeyEvent>!

    var modifiers: [PWKeyboardModifier: PWKeyboardModifierState?] = [:]

    init(_ device: WLRInputDevice<WLRKeyboard>, state: PlywoodState) {
        self.device = device
        self.state = state

        let xkbContext = XKBContext()
        let xkbKeymap = XKBKeymap(context: xkbContext)
        keyboard.keymap = xkbKeymap
        keyboard.repeatConfig = (rate: PlywoodSettings.keyboardRate, delay: PlywoodSettings.keyboardDelay)

        self.modifiersListener = keyboard.onModifiers.listen(onModifiers)
        self.keyListener = keyboard.onKey.listen(onKey)

        state.seat.seat.setKeyboard(device)
    }

    func onModifiers(_: WLRKeyboard) {
        state.seat.seat.setKeyboard(device)
        state.seat.seat.notifyKeyboardModifiers(
            keyboard.modifiers, seat: state.seat.seat)
    }

    func onKey(event: WLRKeyboardKeyEvent) {
        if !tryHandleKey(event.keyCode, event.state) {
            state.seat.seat.notifyKeyboardKey(
                event.keyCode, state: event.state, time: event.timeInMilliseconds)
        }
    }

    func tryHandleKey(_ keyCode: UInt32, _ keyState: WLRKeyState) -> Bool {
        // NOTE: We must add 8 to translate from Wayland keycodes to XKB.
        // https://www.reddit.com/r/swaywm/comments/f96pvw/working_with_keycodes_in_wlroots/firxgxz/?utm_source=reddit&utm_medium=web2x&context=3
        let sym = keyboard.state.getOneSym(keyCode: keyCode + 8)

        // Handle super key.
        if sym == XKBKey.Super_L || sym == XKBKey.Super_R || (PlywoodSettings.keyboardCapsLockModifier && sym == XKBKey.Caps_Lock) {            
            if keyState == .pressed {
                modifiers[.command] = .single
            }

            if keyState == .released {
                if modifiers[.command] == .some(.single) {
                    commandModifierSingle()
                }
                modifiers[.command] = .none
            }

            return true
        }

        if (modifiers[.command] != .none && keyState == .pressed) {
            modifiers[.command] = .multiple

            if (sym == XKBKey.Left || (PlywoodSettings.keyboardWASD && sym == XKBKey.a)) {
                commandModifierLeft()
            }

            if (sym == XKBKey.Right || (PlywoodSettings.keyboardWASD && sym == XKBKey.d)) {
                commandModifierRight()
            }

            if (sym == XKBKey.Up || (PlywoodSettings.keyboardWASD && sym == XKBKey.w)) {
                commandModifierUp()
            }

            if (sym == XKBKey.Down || (PlywoodSettings.keyboardWASD && sym == XKBKey.s)) {
                commandModifierDown()
            }

            return true
        }

        return false
    }

    // TODO: Implement.

    func commandModifierSingle() {
        print("single")
    }

    func commandModifierLeft() {
        state.logger.info("Move stage left")
        state.stage.moveLeft()
    }

    func commandModifierRight() {
        state.logger.info("Move stage right")
        state.stage.moveRight()
    }

    func commandModifierUp() {
        print("up")
    }

    func commandModifierDown() {
        print("down") 
    }

}
