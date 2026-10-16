import Foundation

/// El SDK de analítica (PostHog). Un protocolo para probar sin red (ADR-IOS-0015).
public protocol AnalyticsSDK: Sendable {
    func start() async
    func stop() async
    func resetIdentity() async
}

/// Arranca el SDK solo con consentimiento (ADR-IOS-0026): sin consentimiento no se inicia, y al retirarlo se
/// detiene y se reinicia la identidad seudónima.
public actor AnalyticsCoordinator {
    private let gate: ConsentGate
    private let sdk: AnalyticsSDK
    private var started = false

    public init(gate: ConsentGate, sdk: AnalyticsSDK) {
        self.gate = gate
        self.sdk = sdk
    }

    public func run() async {
        for await granted in await gate.updates() {
            await apply(granted: granted)
        }
    }

    func apply(granted: Bool) async {
        if granted, !started {
            started = true
            await sdk.start()
        } else if !granted, started {
            started = false
            await sdk.stop()
            await sdk.resetIdentity()
        }
    }
}
