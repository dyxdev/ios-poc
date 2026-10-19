// swift-tools-version: 6.0
import PackageDescription

// Paquete local `Core` (ADR-IOS-0002): un paquete con varios targets, uno por responsabilidad. Todos son
// Swift puro (sin SDK de Apple), así que `swift test` los prueba en Linux. Lo que toca el SDK de Apple
// (Keychain, AppAuth, SwiftData, Nuke, App Attest real) vive en un target aparte que se añade en la fase 3.
let package = Package(
    name: "Core",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreModel", targets: ["CoreModel"]),
        .library(name: "CoreVenues", targets: ["CoreVenues"]),
        .library(name: "CoreConsent", targets: ["CoreConsent"]),
        .library(name: "CoreIdentity", targets: ["CoreIdentity"]),
        .library(name: "CoreContext", targets: ["CoreContext"]),
        .library(name: "CoreNetwork", targets: ["CoreNetwork"]),
        .library(name: "CoreUpload", targets: ["CoreUpload"]),
        .library(name: "CoreAttest", targets: ["CoreAttest"]),
        .library(name: "CorePlayback", targets: ["CorePlayback"]),
        .library(name: "CoreLinks", targets: ["CoreLinks"]),
        .library(name: "CoreTesting", targets: ["CoreTesting"])
    ],
    targets: [
        .target(name: "CoreModel"),
        .target(name: "CoreVenues", dependencies: ["CoreModel"]),
        .target(name: "CoreConsent", dependencies: ["CoreModel"]),
        .target(name: "CoreIdentity", dependencies: ["CoreModel"]),
        .target(name: "CoreContext", dependencies: ["CoreModel", "CoreVenues", "CoreConsent", "CoreIdentity"]),
        .target(name: "CoreNetwork", dependencies: ["CoreModel"]),
        .target(name: "CoreUpload", dependencies: ["CoreModel"]),
        .target(name: "CoreAttest", dependencies: ["CoreModel"]),
        .target(name: "CorePlayback"),
        .target(name: "CoreLinks"),
        .target(
            name: "CoreTesting",
            dependencies: [
                "CoreModel", "CoreVenues", "CoreConsent", "CoreIdentity", "CoreContext",
                "CoreNetwork", "CoreUpload", "CoreAttest"
            ]
        ),
        .testTarget(name: "CoreModelTests", dependencies: ["CoreModel"]),
        .testTarget(name: "CoreVenuesTests", dependencies: ["CoreVenues", "CoreModel", "CoreTesting"]),
        .testTarget(name: "CoreConsentTests", dependencies: ["CoreConsent", "CoreTesting"]),
        .testTarget(name: "CoreIdentityTests", dependencies: ["CoreIdentity", "CoreTesting"]),
        .testTarget(
            name: "CoreContextTests",
            dependencies: ["CoreContext", "CoreVenues", "CoreConsent", "CoreIdentity", "CoreTesting"]
        ),
        .testTarget(
            name: "CoreNetworkTests",
            dependencies: ["CoreNetwork", "CoreModel", "CoreIdentity", "CoreTesting"]
        ),
        .testTarget(name: "CoreUploadTests", dependencies: ["CoreUpload", "CoreTesting"]),
        .testTarget(name: "CoreAttestTests", dependencies: ["CoreAttest", "CoreTesting"]),
        .testTarget(name: "CorePlaybackTests", dependencies: ["CorePlayback"]),
        .testTarget(name: "CoreLinksTests", dependencies: ["CoreLinks"])
    ]
)
