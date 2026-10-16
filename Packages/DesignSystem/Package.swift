// swift-tools-version: 6.0
import PackageDescription

// Paquete local `DesignSystem` (ADR-IOS-0002 y 0012). Por ahora solo los tokens, que son Swift puro y se prueban en
// Linux (incluido el contraste de cada par de colores en modo claro y oscuro). La capa SwiftUI (estilos, componentes,
// Liquid Glass, fuente Outfit) se añade en la fase 2 como otro target, solo para Apple.
let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DesignTokens", targets: ["DesignTokens"])
    ],
    targets: [
        .target(name: "DesignTokens"),
        .testTarget(name: "DesignTokensTests", dependencies: ["DesignTokens"]),
    ]
)
