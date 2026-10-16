#if canImport(SwiftUI)
    import DesignTokens
    import SwiftUI

    /// Valoración: estrella y texto ya formateado por quien llama (por idioma: «4,9 (212)»).
    public struct RatingLabel: View {
        private let text: String

        public init(text: String) {
            self.text = text
        }

        public var body: some View {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.text)
                    .accessibilityHidden(true)
                Text(verbatim: text)
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.text)
            }
        }
    }

    /// Disponibilidad: punto y texto. Verde solo cuando está disponible (regla de la web); el estado lo dice el texto,
    /// no solo el color.
    public struct AvailabilityLabel: View {
        private let text: String
        private let isAvailable: Bool

        public init(text: String, isAvailable: Bool) {
            self.text = text
            self.isAvailable = isAvailable
        }

        public var body: some View {
            let tone = isAvailable ? Theme.success : Theme.textMuted
            HStack(spacing: Spacing.xs) {
                Circle().fill(tone).frame(width: 8, height: 8).accessibilityHidden(true)
                Text(verbatim: text)
                    .font(.outfit(.caption))
                    .foregroundStyle(tone)
            }
        }
    }

    public struct SectionHeader: View {
        private let title: String

        public init(_ title: String) {
            self.title = title
        }

        public var body: some View {
            Text(verbatim: title)
                .font(.outfit(.headline))
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
        }
    }
#endif
