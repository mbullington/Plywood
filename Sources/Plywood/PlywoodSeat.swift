import SwiftWayland
import SwiftWLR

class PlywoodSeat {
    let seat: WLRSeat
    private let state: PlywoodState

    var cursorSetRequestListener: WLListener<WLRSeatCursorSetRequestEvent>!

    init(_ seat: WLRSeat, state: PlywoodState) {
        self.seat = seat
        self.state = state

        self.cursorSetRequestListener = seat.onCursorSetRequest
            .listen(onCursorSetRequest)
    }

    func onCursorSetRequest(event: WLRSeatCursorSetRequestEvent) {
        guard seat.pointerState.focusedClient == event.seatClient else {
            return
        }

        state.cursor.cursor.setSurface(event.surface, hotspot: event.hotspot)
    }
}
