// swift-tools-version: 6.0
import PackageDescription

// Paquete SOLO PARA APPLE: interfaz SwiftUI, componentes, funciones y los adaptadores del SDK de Apple (Keychain,
// AppAuth, AVPlayer, URLSession en segundo plano, App Attest). Se compila con Xcode o con `xtool`; en Linux no
// compila (no hay SwiftUI ni UIKit). Los modelos de cada feature son Swift puro y viven aquí junto a sus vistas.
// Dependencias de terceros aprobadas por ADR-IOS-0007 (AppAuth) y ADR-IOS-0024 (Nuke); las versiones se consultaron el
// 2026-10-16 en GitHub (Nuke 13.2.0 y AppAuth-iOS 3.0.0, ambas estables).
let package = Package(
    name: "AppleKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AppStrings", targets: ["AppStrings"]),
        .library(name: "DesignSystemUI", targets: ["DesignSystemUI"]),
        .library(name: "CoreApple", targets: ["CoreApple"]),
        .library(name: "ContextUI", targets: ["ContextUI"]),
        .library(name: "FeatureHome", targets: ["FeatureHome"]),
        .library(name: "FeatureDetail", targets: ["FeatureDetail"]),
        .library(name: "FeatureAccount", targets: ["FeatureAccount"]),
        .library(name: "FeatureOwner", targets: ["FeatureOwner"]),
        .library(name: "FeatureAdmin", targets: ["FeatureAdmin"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(url: "https://github.com/kean/Nuke.git", from: "13.2.0"),
        .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "AppStrings", resources: [.process("Resources")]),
        .target(
            name: "DesignSystemUI",
            dependencies: [
                "AppStrings",
                .product(name: "CoreModel", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "Nuke", package: "Nuke")
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "CoreApple",
            dependencies: [
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreConsent", package: "Core"),
                .product(name: "CoreIdentity", package: "Core"),
                .product(name: "CoreContext", package: "Core"),
                .product(name: "CoreNetwork", package: "Core"),
                .product(name: "CoreUpload", package: "Core"),
                .product(name: "CoreAttest", package: "Core"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "AppAuth", package: "AppAuth-iOS")
            ]
        ),
        .target(
            name: "ContextUI",
            dependencies: [
                "AppStrings", "DesignSystemUI",
                .product(name: "CoreContext", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem")
            ]
        ),
        .target(
            name: "FeatureHome",
            dependencies: [
                "AppStrings", "DesignSystemUI", "ContextUI",
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreVenues", package: "Core"),
                .product(name: "CoreContext", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem")
            ]
        ),
        .target(
            name: "FeatureDetail",
            dependencies: [
                "AppStrings", "DesignSystemUI",
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreVenues", package: "Core"),
                .product(name: "CoreConsent", package: "Core"),
                .product(name: "CorePlayback", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem")
            ]
        ),
        .target(
            name: "FeatureAccount",
            dependencies: [
                "AppStrings", "DesignSystemUI", "ContextUI",
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreVenues", package: "Core"),
                .product(name: "CoreConsent", package: "Core"),
                .product(name: "CoreIdentity", package: "Core"),
                .product(name: "CoreContext", package: "Core"),
                .product(name: "CorePlayback", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem")
            ]
        ),
        .target(
            name: "FeatureOwner",
            dependencies: [
                "AppStrings", "DesignSystemUI", "ContextUI",
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreVenues", package: "Core"),
                .product(name: "CoreContext", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem")
            ]
        ),
        .target(
            name: "FeatureAdmin",
            dependencies: [
                "AppStrings", "DesignSystemUI", "ContextUI",
                .product(name: "CoreContext", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem")
            ]
        ),
        .testTarget(
            name: "FeatureTests",
            dependencies: [
                "AppStrings", "ContextUI", "FeatureHome", "FeatureDetail", "FeatureAccount", "FeatureOwner",
                .product(name: "CoreTesting", package: "Core"),
                .product(name: "CoreVenues", package: "Core"),
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreContext", package: "Core"),
                .product(name: "CoreConsent", package: "Core"),
                .product(name: "CoreIdentity", package: "Core")
            ]
        ),
        .testTarget(
            name: "CoreAppleTests",
            dependencies: [
                "CoreApple",
                .product(name: "CoreTesting", package: "Core"),
                .product(name: "CoreUpload", package: "Core"),
                .product(name: "CoreIdentity", package: "Core")
            ]
        )
    ]
)
