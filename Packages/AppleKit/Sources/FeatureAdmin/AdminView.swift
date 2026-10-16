#if canImport(SwiftUI)
    import AppStrings
    import ContextUI
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Administración: pantalla de EJEMPLO sin datos (el panel real llega con la API). Existe para probar el tercer
    /// contexto del cambio de perfil.
    public struct AdminView: View {
        private let switcher: ContextSwitcherModel

        public init(switcher: ContextSwitcherModel) {
            self.switcher = switcher
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text(verbatim: AppStrings.text("admin.title"))
                        .font(.outfit(.title))
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    ContextLabel(model: switcher)
                }
                Text(verbatim: AppStrings.text("owner.sample.note"))
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
                Text(verbatim: AppStrings.text("admin.placeholder"))
                    .font(.outfit(.body))
                    .foregroundStyle(Theme.text)
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .background(Theme.background)
        }
    }
#endif
