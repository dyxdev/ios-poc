#if canImport(SwiftUI)
    import DesignTokens
    import SwiftUI

    /// Botón principal rectangular de 8 pt (sin píldora) y 44 pt de alto mínimo.
    public struct PrimaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled

        public init() {}

        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.outfit(.label))
                .foregroundStyle(Theme.onPrimary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                .background(
                    Theme.primary.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4),
                    in: RoundedRectangle(cornerRadius: Radius.standard)
                )
        }
    }

    /// Botón secundario: mismo tamaño y forma, con borde y sin relleno.
    public struct SecondaryButtonStyle: ButtonStyle {
        public init() {}

        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.outfit(.label))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: Radius.standard)
                        .stroke(Theme.border.opacity(configuration.isPressed ? 0.6 : 1), lineWidth: 1.5)
                )
        }
    }

    /// Campo de búsqueda rectangular de 8 pt, con botón para borrar cuando hay texto.
    public struct SearchField: View {
        @Binding private var text: String
        private let placeholder: String
        private let clearLabel: String

        public init(text: Binding<String>, placeholder: String, clearLabel: String) {
            _text = text
            self.placeholder = placeholder
            self.clearLabel = clearLabel
        }

        public var body: some View {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textMuted)
                    .accessibilityHidden(true)
                TextField(placeholder, text: $text)
                    .font(.outfit(.body))
                    .foregroundStyle(Theme.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textMuted)
                            .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                    }
                    .accessibilityLabel(clearLabel)
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: Layout.minTouchTarget)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.standard))
            .overlay(RoundedRectangle(cornerRadius: Radius.standard).stroke(Theme.border, lineWidth: 1))
        }
    }

    /// Chip de categoría: rectangular de 8 pt; seleccionado = tinte violeta con texto violeta oscuro.
    public struct CategoryChip: View {
        private let title: String
        private let isSelected: Bool
        private let action: () -> Void

        public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
            self.title = title
            self.isSelected = isSelected
            self.action = action
        }

        public var body: some View {
            Button(action: action) {
                Text(verbatim: title)
                    .font(.outfit(.label))
                    .foregroundStyle(isSelected ? Theme.onAccent : Theme.text)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: Layout.minTouchTarget)
                    .background(
                        isSelected ? Theme.accent : Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.standard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.standard)
                            .stroke(isSelected ? Theme.primary : Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }

    extension View {
        /// Tarjeta plana de la web: superficie, borde de 1 pt y esquina de 8 pt (12 pt solo en destacados).
        public func cardStyle(radius: Double = Radius.standard) -> some View {
            background(Theme.surface, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: radius))
        }
    }
#endif
