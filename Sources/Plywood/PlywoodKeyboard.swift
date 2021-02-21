import SwiftWayland
import SwiftWLR

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

    init(_ device: WLRInputDevice<WLRKeyboard>, state: PlywoodState) {
        self.device = device
        self.state = state

        let xkbContext = XKBContext()
        let xkbKeymap = XKBKeymap(context: xkbContext)
        keyboard.keymap = xkbKeymap
        keyboard.repeatConfig = (rate: 25, delay: 600)

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
        state.seat.seat.notifyKeyboardKey(
            event.keyCode, state: event.state, time: event.timeInMilliseconds)
    }
}
