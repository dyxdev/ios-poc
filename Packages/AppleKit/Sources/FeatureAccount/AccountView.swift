#if canImport(SwiftUI)
    import AppStrings
    import ContextUI
    import CoreIdentity
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Cuenta (decisión de Andy, 2026-10-15): tarjeta de sesión con la caducidad del acceso, Google por `kc_idp_hint`,
    /// perfil activo con botón de cambio, privacidad (consentimiento de analítica por persona, ADR-AND-0033 en
    /// paridad) y, solo en compilaciones de desarrollo, Diagnóstico.
    public struct AccountView: View {
        private let model: AccountModel
        private let switcher: ContextSwitcherModel
        private let showsDiagnostics: Bool
        private let onOpenDiagnostics: () -> Void

        public init(
            model: AccountModel,
            switcher: ContextSwitcherModel,
            showsDiagnostics: Bool,
            onOpenDiagnostics: @escaping () -> Void
        ) {
            self.model = model
            self.switcher = switcher
            self.showsDiagnostics = showsDiagnostics
            self.onOpenDiagnostics = onOpenDiagnostics
        }

        public var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(verbatim: AppStrings.text("account.title"))
                        .font(.outfit(.title))
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    sessionCard
                    if model.isSignedIn, switcher.state.canSwitch {
                        profileCard
                    }
                    privacyCard
                    if showsDiagnostics {
                        diagnosticsCard
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Theme.background)
            .task { await model.observeIdentity() }
            .task { await model.observeConsent() }
        }

        private var sessionCard: some View {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if model.isSignedIn {
                    Text(verbatim: AppStrings.text("account.signedin.title"))
                        .font(.outfit(.headline))
                        .foregroundStyle(Theme.text)
                    Text(verbatim: signedInSubtitle)
                        .font(.outfit(.body))
                        .foregroundStyle(Theme.textMuted)
                    Button(AppStrings.text("account.signout")) { model.signOut() }
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Text(verbatim: AppStrings.text("account.guest.title"))
                        .font(.outfit(.headline))
                        .foregroundStyle(Theme.text)
                    Text(verbatim: AppStrings.text("account.guest.subtitle"))
                        .font(.outfit(.body))
                        .foregroundStyle(Theme.textMuted)
                    if let error = model.identity.error {
                        Text(verbatim: AppStrings.text(error.messageKey))
                            .font(.outfit(.body))
                            .foregroundStyle(Theme.text)
                            .accessibilityAddTraits(.isStaticText)
                    }
                    Button(AppStrings.text("account.signin")) { model.signIn() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button(AppStrings.text("account.signin.google")) { model.signIn(idpHint: "google") }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .cardStyle()
        }

        private var signedInSubtitle: String {
            if let until = model.expiryText(locale: .current) {
                return AppStrings.format("account.signedin.until", until)
            }
            return AppStrings.text("account.signedin.active")
        }

        private var profileCard: some View {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(AppStrings.text("account.profile.title"))
                Text(verbatim: AppStrings.text(switcher.state.active.titleKey))
                    .font(.outfit(.body))
                    .foregroundStyle(Theme.text)
                Button(AppStrings.text("account.profile.switch")) { switcher.openSheet() }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .cardStyle()
        }

        private var privacyCard: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(AppStrings.text("account.privacy.title"))
                Toggle(
                    isOn: Binding(
                        get: { model.analyticsConsent },
                        set: { model.setAnalyticsConsent($0) }
                    )
                ) {
                    Text(verbatim: AppStrings.text("account.analytics.title"))
                        .font(.outfit(.body))
                        .foregroundStyle(Theme.text)
                }
                .tint(Theme.primary)
                .frame(minHeight: Layout.minTouchTarget)
                Text(verbatim: AppStrings.text("account.analytics.description"))
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .cardStyle()
        }

        private var diagnosticsCard: some View {
            Button(action: onOpenDiagnostics) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: AppStrings.text("account.diagnostics.title"))
                        .font(.outfit(.headline))
                        .foregroundStyle(Theme.text)
                    Text(verbatim: AppStrings.text("account.diagnostics.subtitle"))
                        .font(.outfit(.caption))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
                .padding(Spacing.lg)
                .cardStyle()
            }
            .buttonStyle(.plain)
        }
    }
#endif
