#if canImport(SwiftUI)
    import DesignTokens
    import SwiftUI

    /// Marca provisional de la web: wordmark tipográfico con un arco de puerta (aún no hay logotipo real).
    public struct VenueNexaWordmark: View {
        public init() {}

        public var body: some View {
            HStack(spacing: Spacing.sm) {
                DoorArch()
                    .stroke(Theme.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 24)
                    .accessibilityHidden(true)
                Text(verbatim: "VenueNexa")
                    .font(.outfit(.title))
                    .foregroundStyle(Theme.text)
            }
            .accessibilityElement(children: .combine)
        }
    }

    struct DoorArch: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let inset: CGFloat = 1.25
            let width = rect.width - inset * 2
            path.move(to: CGPoint(x: inset, y: rect.maxY))
            path.addLine(to: CGPoint(x: inset, y: width / 2 + inset))
            path.addArc(
                center: CGPoint(x: rect.midX, y: width / 2 + inset),
                radius: width / 2,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
            return path
        }
    }
#endif
