#if canImport(SwiftUI)
    import NukeUI
    import SwiftUI

    /// Foto de un venue con Nuke (ADR-IOS-0024): brillo mientras carga y bloque neutro si falla. La caché de disco se
    /// vacía al cerrar sesión (`CoreApple.ImageCaches`). El llamador elige la rendition (ancho) al construir la URL.
    public struct VenueImage: View {
        private let url: URL
        private let accessibilityText: String?

        public init(url: URL, accessibilityText: String?) {
            self.url = url
            self.accessibilityText = accessibilityText
        }

        public var body: some View {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if state.error != nil {
                    Theme.border.opacity(0.5)
                } else {
                    ShimmerBox()
                }
            }
            .accessibilityHidden(accessibilityText == nil)
            .accessibilityLabel(accessibilityText ?? "")
        }
    }
#endif
