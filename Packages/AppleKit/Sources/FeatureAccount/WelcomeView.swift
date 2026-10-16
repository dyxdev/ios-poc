#if canImport(SwiftUI)
    import AppStrings
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Bienvenida de primer uso: collage de portadas, mensaje y «Explorar / Iniciar sesión». Se cierra al elegir
    /// «Explorar» o cuando la sesión se inició desde aquí; la restauración de una sesión guardada no la salta.
    public struct WelcomeView: View {
        private let model: WelcomeModel
        private let onFinish: () -> Void
        @Environment(\.displayScale) private var displayScale

        public init(model: WelcomeModel, onFinish: @escaping () -> Void) {
            self.model = model
            self.onFinish = onFinish
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                collage
                VenueNexaWordmark()
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(verbatim: AppStrings.text("welcome.headline"))
                        .font(.outfit(.display))
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: AppStrings.text("welcome.subtitle"))
                        .font(.outfit(.body))
                        .foregroundStyle(Theme.textMuted)
                }
                if let error = model.identity.error, model.signInRequested {
                    Text(verbatim: AppStrings.text(error.messageKey))
                        .font(.outfit(.body))
                        .foregroundStyle(Theme.text)
                }
                VStack(spacing: Spacing.md) {
                    Button(AppStrings.text("welcome.explore")) { finish() }
                        .buttonStyle(PrimaryButtonStyle())
                    if model.showsSignIn {
                        Button(AppStrings.text("account.signin")) { model.requestSignIn() }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .task { await model.loadCovers() }
            .task { await model.observeIdentity() }
            .onChange(of: model.shouldFinishAfterSignIn) { _, shouldFinish in
                if shouldFinish { finish() }
            }
        }

        private func finish() {
            Task {
                await model.markSeen()
                onFinish()
            }
        }

        private func cover(_ url: URL, points: Double) -> some View {
            VenueImage(url: RenditionURL.make(for: url, points: points, scale: displayScale), accessibilityText: nil)
        }

        @ViewBuilder private var collage: some View {
            if let covers = model.covers, covers.count >= 3 {
                HStack(spacing: Spacing.sm) {
                    cover(covers[0], points: 180)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.featured))
                    VStack(spacing: Spacing.sm) {
                        cover(covers[1], points: 160)
                            .frame(height: 126)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.featured))
                        cover(covers[2], points: 160)
                            .frame(height: 126)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.featured))
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 260)
                .accessibilityHidden(true)
            } else {
                ShimmerBox()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.featured))
                    .accessibilityHidden(true)
            }
        }
    }
#endif
