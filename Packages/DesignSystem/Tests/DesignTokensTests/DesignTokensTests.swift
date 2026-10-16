import Testing

@testable import DesignTokens

struct ContrastTests {
    @Test func blackOnWhiteIs21AndSameColorIs1() {
        #expect(abs(Contrast.ratio(HexColor(0x000000), HexColor(0xFFFFFF)) - 21) < 0.01)
        #expect(abs(Contrast.ratio(HexColor(0x7C3AED), HexColor(0x7C3AED)) - 1) < 0.0001)
    }

    @Test func orderDoesNotMatter() {
        let a = HexColor(0x141217)
        let b = HexColor(0xF4F3EF)
        #expect(Contrast.ratio(a, b) == Contrast.ratio(b, a))
    }
}

struct PaletteContrastTests {
    /// Los pares de texto deben llegar a 4,5:1 (WCAG AA) en los dos modos.
    private func textPairs(_ palette: Palette) -> [(name: String, ratio: Double)] {
        [
            ("text/background", Contrast.ratio(palette.text, palette.background)),
            ("text/surface", Contrast.ratio(palette.text, palette.surface)),
            ("textMuted/background", Contrast.ratio(palette.textMuted, palette.background)),
            ("textMuted/surface", Contrast.ratio(palette.textMuted, palette.surface)),
            ("onPrimary/primary", Contrast.ratio(palette.onPrimary, palette.primary)),
            ("onAccent/accent", Contrast.ratio(palette.onAccent, palette.accent)),
            ("success/surface", Contrast.ratio(palette.success, palette.surface)),
            ("primary/surface", Contrast.ratio(palette.primary, palette.surface)),
        ]
    }

    @Test func lightTextPairsMeetAA() {
        for pair in textPairs(.light) {
            #expect(pair.ratio >= 4.5, "\(pair.name) = \(pair.ratio)")
        }
    }

    @Test func darkTextPairsMeetAA() {
        for pair in textPairs(.dark) {
            #expect(pair.ratio >= 4.5, "\(pair.name) = \(pair.ratio)")
        }
    }

    @Test func successOnTheLightBackgroundIsOnlyJustAA() {
        // El verde sobre el papel cálido (no sobre blanco) queda en el límite: se usa solo sobre tarjeta blanca.
        #expect(Contrast.ratio(Palette.light.success, Palette.light.background) >= 4.5)
    }
}

struct WebIdentityTests {
    @Test func lightPaletteKeepsTheWebHexValues() {
        #expect(Palette.light.background == HexColor(0xF4F3EF))
        #expect(Palette.light.primary == HexColor(0x7C3AED))
        #expect(Palette.light.success == HexColor(0x15803D))
    }

    @Test func shapesFollowTheWeb() {
        #expect(Radius.standard == 8)
        #expect(Radius.featured == 12)
        #expect(Layout.photoAspect == 1.5)
    }
}
