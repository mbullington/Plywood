// FIXME: Use dconf or similar for this.
final class PlywoodSettings {
    public static let stagePadding = 56.0
    public static let stageSpacing = 24.0
    public static let crossAxisFactor = 0.9

    public static let keyboardRate: Int32 = 25
    public static let keyboardDelay: Int32 = 600

    // If true, Plywood will interpret Caps Lock as the Command/"Windows" modifier.    
    public static let keyboardCapsLockModifier: Bool = true
    // If true, Plywood can be controlled with Super+WASD in addition to arrow keys.
    public static let keyboardWASD: Bool = true
}