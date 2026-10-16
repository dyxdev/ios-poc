#if canImport(SwiftUI)
    import CoreText
    import SwiftUI

    /// Tipografía Outfit empaquetada (SIL OFL, ver `OFL-Outfit.txt`) con escalado de Dynamic Type: cada estilo se
    /// ancla a un estilo de texto del sistema con `relativeTo`. Decisión de Andy (2026-10-16): fuente propia aceptada.
    public enum OutfitStyle {
        case display, title, headline, body, label, caption

        var size: CGFloat {
            switch self {
            case .display: 38
            case .title: 28
            case .headline: 18
            case .body: 16
            case .label: 15
            case .caption: 13
            }
        }

        var weight: Font.Weight {
            switch self {
            case .display: .heavy
            case .title: .bold
            case .headline: .semibold
            case .body: .regular
            case .label: .semibold
            case .caption: .medium
            }
        }

        var anchor: Font.TextStyle {
            switch self {
            case .display: .largeTitle
            case .title: .title
            case .headline: .headline
            case .body: .body
            case .label: .subheadline
            case .caption: .caption
            }
        }
    }

    extension Font {
        public static func outfit(_ style: OutfitStyle) -> Font {
            .custom("Outfit", size: style.size, relativeTo: style.anchor).weight(style.weight)
        }
    }

    public enum FontRegistration {
        /// Registra la fuente empaquetada en el proceso. Se llama una vez al arrancar la app.
        public static func registerOutfit() {
            guard let url = Bundle.module.url(forResource: "Outfit", withExtension: "ttf") else { return }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
#endif
