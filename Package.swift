// swift-tools-version: 6.0
import PackageDescription

// App de la PoC de iOS. La biblioteca `VenueNexaApp` es el punto de entrada: Xcode (proyecto generado/abierto desde este
// paquete) o `xtool` (ver `xtool.yml`) la empaquetan como .app. La lógica vive en `Packages/` y se prueba allí.
// Sin verificar: que `xtool` acepte este formato y que el esquema se llame `VenueNexaApp`.
let package = Package(
    name: "VenueNexaApp",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "VenueNexaApp", targets: ["VenueNexaApp"])
    ],
    dependencies: [
        .package(path: "Packages/Core"),
        .package(path: "Packages/DesignSystem"),
        .package(path: "Packages/AppleKit"),
    ],
    targets: [
        .target(
            name: "VenueNexaApp",
            dependencies: [
                .product(name: "CoreModel", package: "Core"),
                .product(name: "CoreVenues", package: "Core"),
                .product(name: "CoreConsent", package: "Core"),
                .product(name: "CoreIdentity", package: "Core"),
                .product(name: "CoreContext", package: "Core"),
                .product(name: "CoreLinks", package: "Core"),
                .product(name: "DesignTokens", package: "DesignSystem"),
                .product(name: "AppStrings", package: "AppleKit"),
                .product(name: "DesignSystemUI", package: "AppleKit"),
                .product(name: "CoreApple", package: "AppleKit"),
                .product(name: "ContextUI", package: "AppleKit"),
                .product(name: "FeatureHome", package: "AppleKit"),
                .product(name: "FeatureDetail", package: "AppleKit"),
                .product(name: "FeatureAccount", package: "AppleKit"),
                .product(name: "FeatureOwner", package: "AppleKit"),
                .product(name: "FeatureAdmin", package: "AppleKit"),
            ]
        )
    ]
)
