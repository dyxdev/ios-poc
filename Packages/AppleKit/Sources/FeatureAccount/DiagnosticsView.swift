#if canImport(SwiftUI)
    import AppStrings
    import CoreContext
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Diagnóstico de desarrollo (solo se enlaza desde Cuenta en debug): simulador de capacidades, restablecer la
    /// bienvenida y evaluación de una captura de red contra ADR-IOS-0029 (0 peticiones a `*.litix.io`).
    public struct DiagnosticsView: View {
        @Bindable private var model: DiagnosticsModel
        private let signedIn: Bool
        private let onBack: () -> Void

        public init(model: DiagnosticsModel, signedIn: Bool, onBack: @escaping () -> Void) {
            self.model = model
            self.signedIn = signedIn
            self.onBack = onBack
        }

        public var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Button(action: onBack) {
                        Label(AppStrings.text("diagnostics.back"), systemImage: "chevron.left")
                            .font(.outfit(.label))
                            .foregroundStyle(Theme.text)
                            .frame(minHeight: Layout.minTouchTarget)
                    }
                    Text(verbatim: AppStrings.text("diagnostics.title"))
                        .font(.outfit(.title))
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    if model.hasSimulator {
                        simulatorCard
                    }
                    resetCard
                    evidenceCard
                }
                .padding(Spacing.lg)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .task { await model.load() }
        }

        private var simulatorCard: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(AppStrings.text("diagnostics.sim.title"))
                Text(verbatim: AppStrings.text("diagnostics.sim.description"))
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
                simulatorToggle("diagnostics.sim.owner", context: .owner, isOn: model.ownerGranted)
                simulatorToggle("diagnostics.sim.admin", context: .admin, isOn: model.adminGranted)
                if !signedIn {
                    Text(verbatim: AppStrings.text("diagnostics.sim.needssession"))
                        .font(.outfit(.caption))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .cardStyle()
        }

        private func simulatorToggle(_ key: String, context: UserContext, isOn: Bool) -> some View {
            Toggle(
                isOn: Binding(get: { isOn }, set: { model.setGranted(context, $0) })
            ) {
                Text(verbatim: AppStrings.text(key)).font(.outfit(.body)).foregroundStyle(Theme.text)
            }
            .tint(Theme.primary)
            .frame(minHeight: Layout.minTouchTarget)
        }

        private var resetCard: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Button(AppStrings.text("diagnostics.reset")) { model.resetOnboarding() }
                    .buttonStyle(SecondaryButtonStyle())
                Text(verbatim: AppStrings.text("diagnostics.reset.note"))
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .cardStyle()
        }

        private var evidenceCard: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(AppStrings.text("diagnostics.evidence.title"))
                Text(verbatim: AppStrings.text("diagnostics.evidence.description"))
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
                TextEditor(text: $model.capturedHosts)
                    .font(.system(.footnote, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(Spacing.sm)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: Radius.standard))
                    .overlay(RoundedRectangle(cornerRadius: Radius.standard).stroke(Theme.border, lineWidth: 1))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(AppStrings.text("diagnostics.evidence.evaluate")) { model.evaluateCapture() }
                    .buttonStyle(PrimaryButtonStyle())
                if let violations = model.violations {
                    if violations.isEmpty {
                        Text(verbatim: AppStrings.text("diagnostics.evidence.pass"))
                            .font(.outfit(.label))
                            .foregroundStyle(Theme.success)
                    } else {
                        Text(verbatim: AppStrings.format("diagnostics.evidence.fail", violations.count))
                            .font(.outfit(.label))
                            .foregroundStyle(Theme.text)
                        ForEach(violations, id: \.self) { host in
                            Text(verbatim: host).font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(Theme.text)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .cardStyle()
        }
    }
#endif
