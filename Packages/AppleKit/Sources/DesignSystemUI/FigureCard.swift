#if canImport(SwiftUI)
    import DesignTokens
    import SwiftUI

    /// Cifra que cuenta desde 0 hasta su valor al aparecer (una vez). Con «Reducir movimiento» muestra el valor final.
    public struct CountingText: View {
        private let target: Int
        private let format: (Int) -> String
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var shown = 0

        public init(target: Int, format: @escaping (Int) -> String = { String($0) }) {
            self.target = target
            self.format = format
        }

        public var body: some View {
            Text(verbatim: format(reduceMotion ? target : shown))
                .contentTransition(.numericText())
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeOut(duration: 0.7)) { shown = target }
                }
        }
    }

    /// Cifra clave con su etiqueta (capacidad, precio, opiniones, reservas…).
    public struct FigureCard<Value: View>: View {
        private let label: String
        private let value: Value

        public init(label: String, @ViewBuilder value: () -> Value) {
            self.label = label
            self.value = value()
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                value
                    .font(.outfit(.title))
                    .foregroundStyle(Theme.text)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(verbatim: label)
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            .accessibilityElement(children: .combine)
        }
    }
#endif
