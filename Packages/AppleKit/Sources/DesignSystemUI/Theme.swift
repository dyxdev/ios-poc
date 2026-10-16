#if canImport(SwiftUI)
    import DesignTokens
    import SwiftUI

    #if canImport(UIKit)
        import UIKit
    #endif

    extension Color {
        init(hex: HexColor) {
            self.init(.sRGB, red: hex.red, green: hex.green, blue: hex.blue, opacity: 1)
        }

        /// Un color que cambia solo entre modo claro y oscuro (equivale a una variante en el catálogo de assets).
        init(light: HexColor, dark: HexColor) {
            #if canImport(UIKit)
                self.init(
                    uiColor: UIColor { traits in
                        let hex = traits.userInterfaceStyle == .dark ? dark : light
                        return UIColor(red: hex.red, green: hex.green, blue: hex.blue, alpha: 1)
                    }
                )
            #else
                self.init(hex: light)
            #endif
        }
    }

    /// Colores semánticos de VenueNexa (ADR-IOS-0012). Los valores salen de `DesignTokens`, donde se prueba su
    /// contraste.
    public enum Theme {
        public static let background = Color(light: Palette.light.background, dark: Palette.dark.background)
        public static let surface = Color(light: Palette.light.surface, dark: Palette.dark.surface)
        public static let text = Color(light: Palette.light.text, dark: Palette.dark.text)
        public static let textMuted = Color(light: Palette.light.textMuted, dark: Palette.dark.textMuted)
        public static let primary = Color(light: Palette.light.primary, dark: Palette.dark.primary)
        public static let onPrimary = Color(light: Palette.light.onPrimary, dark: Palette.dark.onPrimary)
        public static let accent = Color(light: Palette.light.accent, dark: Palette.dark.accent)
        public static let onAccent = Color(light: Palette.light.onAccent, dark: Palette.dark.onAccent)
        public static let border = Color(light: Palette.light.border, dark: Palette.dark.border)
        public static let success = Color(light: Palette.light.success, dark: Palette.dark.success)
    }
#endif
