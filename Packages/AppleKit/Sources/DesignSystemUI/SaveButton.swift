#if canImport(SwiftUI)
    import DesignTokens
    import SwiftUI

    /// Corazón de guardar: al marcarlo rebota (sobrio; «Reducir movimiento» lo anula). Zona táctil de 44 pt (HIG).
    public struct SaveButton: View {
        private let isSaved: Bool
        private let label: String
        private let action: () -> Void

        public init(isSaved: Bool, label: String, action: @escaping () -> Void) {
            self.isSaved = isSaved
            self.label = label
            self.action = action
        }

        public var body: some View {
            Button(action: action) {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundStyle(isSaved ? Theme.primary : Theme.textMuted)
                    .symbolEffect(.bounce, value: isSaved)
                    .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            .accessibilityAddTraits(isSaved ? .isSelected : [])
        }
    }
#endif
