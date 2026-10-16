import Foundation

/// Un color como valor 0xRRGGBB. Sin SwiftUI: así se puede probar en Linux.
public struct HexColor: Sendable, Equatable {
    public let value: UInt32

    public init(_ value: UInt32) {
        self.value = value
    }

    public var red: Double { Double((value >> 16) & 0xFF) / 255 }
    public var green: Double { Double((value >> 8) & 0xFF) / 255 }
    public var blue: Double { Double(value & 0xFF) / 255 }

    /// Luminancia relativa de WCAG 2.x.
    public var luminance: Double {
        func channel(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }
}

public enum Contrast {
    /// Relación de contraste de WCAG entre dos colores (de 1 a 21).
    public static func ratio(_ first: HexColor, _ second: HexColor) -> Double {
        let lighter = max(first.luminance, second.luminance)
        let darker = min(first.luminance, second.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// Los colores semánticos de VenueNexa para un modo (claro u oscuro). En la app van en el catálogo de assets con
/// su variante de cada modo (ADR-IOS-0012); este tipo es la fuente de los valores y la prueba de su contraste.
public struct Palette: Sendable, Equatable {
    public let background: HexColor
    public let surface: HexColor
    public let text: HexColor
    public let textMuted: HexColor
    public let primary: HexColor
    public let onPrimary: HexColor
    public let accent: HexColor
    public let onAccent: HexColor
    public let border: HexColor
    /// Verde solo para dinero y disponibilidad (regla de la web).
    public let success: HexColor

    /// Identidad de la web (`test-mux/design-system/venuenexa/MASTER.md`).
    public static let light = Palette(
        background: HexColor(0xF4F3EF),
        surface: HexColor(0xFFFFFF),
        text: HexColor(0x141217),
        textMuted: HexColor(0x57535E),
        primary: HexColor(0x7C3AED),
        onPrimary: HexColor(0xFFFFFF),
        accent: HexColor(0xF3EFFD),
        onAccent: HexColor(0x5B21B6),
        border: HexColor(0xE2DED6),
        success: HexColor(0x15803D)
    )

    /// PROPUESTA de paleta oscura (la web y los ADR no la definen; Andy decidió el 2026-10-16 que el modo oscuro se
    /// soporta en todo). Contrastes medidos en las pruebas; pendiente de aprobación de Andy con capturas reales.
    public static let dark = Palette(
        background: HexColor(0x141217),
        surface: HexColor(0x1E1B24),
        text: HexColor(0xF4F3EF),
        textMuted: HexColor(0xB8B3C2),
        primary: HexColor(0xA78BFA),
        onPrimary: HexColor(0x141217),
        accent: HexColor(0x2A2145),
        onAccent: HexColor(0xDDD3FF),
        border: HexColor(0x3F3A4A),
        success: HexColor(0x4ADE80)
    )
}

/// Espaciado compacto (rejillas de 12–16 pt) y formas: 8 pt, 12 pt solo en destacados; fotos 3:2.
public enum Spacing {
    public static let xs = 4.0
    public static let sm = 8.0
    public static let md = 12.0
    public static let lg = 16.0
    public static let xl = 24.0
    public static let xxl = 32.0
}

public enum Radius {
    public static let standard = 8.0
    public static let featured = 12.0
}

public enum Layout {
    /// Relación ancho/alto de las fotos de las tarjetas.
    public static let photoAspect = 3.0 / 2.0
    /// Zona táctil mínima de HIG.
    public static let minTouchTarget = 44.0
}
