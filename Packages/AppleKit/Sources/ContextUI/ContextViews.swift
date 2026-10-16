#if canImport(SwiftUI)
    import AppStrings
    import CoreContext
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Indicador permanente del contexto activo y, a la vez, botón para cambiarlo. Solo aparece si la persona tiene más
    /// de un contexto. Con un aviso pendiente suma un punto y un globo explicativo (una vez por contexto nuevo).
    public struct ContextLabel: View {
        private let model: ContextSwitcherModel

        public init(model: ContextSwitcherModel) {
            self.model = model
        }

        public var body: some View {
            if model.state.canSwitch {
                Button {
                    model.openSheet()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(verbatim: AppStrings.text(model.state.active.titleKey))
                            .font(.outfit(.label))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: Layout.minTouchTarget)
                    .cardStyle()
                    .overlay(alignment: .topTrailing) {
                        if model.state.hintPending {
                            Circle().fill(Theme.primary).frame(width: 8, height: 8).offset(x: 2, y: 8)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    AppStrings.format("context.label.description", AppStrings.text(model.state.active.titleKey))
                )
                .popover(isPresented: hintBinding, arrowEdge: .top) {
                    HintBalloon { Task { await model.acknowledgeHint() } }
                        .presentationCompactAdaptation(.popover)
                }
            }
        }

        private var hintBinding: Binding<Bool> {
            Binding(
                get: { model.state.hintPending && !model.isSheetPresented },
                set: { shown in
                    if !shown { Task { await model.acknowledgeHint() } }
                }
            )
        }
    }

    private struct HintBalloon: View {
        let onDismiss: () -> Void

        var body: some View {
            VStack(alignment: .trailing, spacing: Spacing.sm) {
                Text(verbatim: AppStrings.text("context.hint"))
                    .font(.outfit(.body))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Button(AppStrings.text("context.hint.ok"), action: onDismiss)
                    .font(.outfit(.label))
                    .frame(minHeight: Layout.minTouchTarget)
            }
            .padding(Spacing.md)
            .frame(maxWidth: 260)
        }
    }

    /// Hoja con una fila grande por contexto. El actual se marca con icono y texto (no solo con color).
    public struct ContextSheet: View {
        private let model: ContextSwitcherModel

        public init(model: ContextSwitcherModel) {
            self.model = model
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(verbatim: AppStrings.text("context.sheet.title"))
                    .font(.outfit(.title))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: AppStrings.text("context.sheet.subtitle"))
                    .font(.outfit(.body))
                    .foregroundStyle(Theme.textMuted)
                ForEach(model.state.available, id: \.self) { context in
                    row(context)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .background(Theme.background)
            .presentationDetents([.medium])
        }

        private func row(_ context: UserContext) -> some View {
            let isActive = context == model.state.active
            return Button {
                model.select(context)
            } label: {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(verbatim: AppStrings.text(context.titleKey))
                            .font(.outfit(.headline))
                            .foregroundStyle(Theme.text)
                        Text(verbatim: AppStrings.text(context.descriptionKey))
                            .font(.outfit(.caption))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark").accessibilityHidden(true)
                        Text(verbatim: AppStrings.text("context.current")).font(.outfit(.caption))
                    }
                }
                .foregroundStyle(isActive ? Theme.onAccent : Theme.text)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .background(
                    isActive ? Theme.accent : Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.standard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.standard)
                        .stroke(isActive ? Theme.primary : Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
        }
    }
#endif
