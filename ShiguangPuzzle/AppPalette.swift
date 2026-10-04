import SpriteKit
import SwiftUI

/// Shared warm, light colors for both SwiftUI chrome and the SpriteKit board.
enum AppPalette {
    static let background = color(0xFFF8ED)
    static let surface = color(0xFFFDFA)
    static let surfaceSoft = color(0xF9EBDD)
    static let peach = color(0xFAD9BB)
    static let sunshine = color(0xFFE7AA)
    static let text = color(0x51382D)
    static let secondary = color(0x856653)
    static let accent = color(0xB6532D)
    static let border = color(0xE8CDB4)
    static let shadow = color(0x8C5835)

    enum Board {
        static let background = nativeColor(0xF4E4CF)
        static let tray = nativeColor(0xFFFAF2)
        static let slot = nativeColor(0xF6EADB)
        static let border = nativeColor(0xD8B899)
        static let text = nativeColor(0x73503A)
        static let button = nativeColor(0xFAD9BB)
        static let accent = nativeColor(0xB6532D)
    }

    private static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }

    private static func nativeColor(_ hex: UInt32) -> SKColor {
        SKColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
