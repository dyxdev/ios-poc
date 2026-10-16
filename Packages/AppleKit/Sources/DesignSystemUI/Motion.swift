#if canImport(SwiftUI)
    import SwiftUI

    /// Movimiento sobrio y con intención (decisión de Andy, 2026-10-15). Todo respeta «Reducir movimiento».
    private struct StaggeredEntrance: ViewModifier {
        let index: Int
        let play: Bool
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var visible = false

        func body(content: Content) -> some View {
            let animate = play && !reduceMotion
            content
                .opacity(animate && !visible ? 0 : 1)
                .offset(y: animate && !visible ? 24 : 0)
                .onAppear {
                    guard animate else { return }
                    withAnimation(.easeOut(duration: 0.32).delay(Double(index) * 0.06)) {
                        visible = true
                    }
                }
        }
    }

    private struct Shimmer: ViewModifier {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var phase: CGFloat = -1

        func body(content: Content) -> some View {
            content
                .overlay {
                    if !reduceMotion {
                        GeometryReader { proxy in
                            LinearGradient(
                                colors: [.clear, Theme.surface.opacity(0.55), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: proxy.size.width)
                            .offset(x: phase * proxy.size.width * 2)
                        }
                        .clipped()
                    }
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }

    extension View {
        /// Aparece con un fundido y un pequeño desplazamiento, retrasada según su posición en la lista.
        public func staggeredEntrance(index: Int, play: Bool) -> some View {
            modifier(StaggeredEntrance(index: min(index, 5), play: play))
        }

        /// Brillo de carga para los marcadores de posición.
        public func shimmer() -> some View {
            modifier(Shimmer())
        }
    }

    /// Un marcador de posición con brillo (fotos y tarjetas mientras cargan).
    public struct ShimmerBox: View {
        public init() {}

        public var body: some View {
            Rectangle()
                .fill(Theme.border.opacity(0.6))
                .shimmer()
                .accessibilityHidden(true)
        }
    }
#endif
