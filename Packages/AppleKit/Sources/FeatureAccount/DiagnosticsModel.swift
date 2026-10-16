import CoreContext
import CorePlayback
import Foundation
import Observation

/// Herramientas de diagnóstico, SOLO de desarrollo (en release la tarjeta no se muestra): simulador de capacidades
/// (ADR-IOS-0022), restablecer la bienvenida y los avisos, y evaluación de una captura de red contra ADR-IOS-0029.
@MainActor
@Observable
public final class DiagnosticsModel {
    public private(set) var ownerGranted = false
    public private(set) var adminGranted = false
    public var capturedHosts = ""
    public private(set) var violations: [String]?

    private let simulator: CapabilitySimulator?
    private let onboarding: OnboardingStore
    private let onChange: @MainActor () async -> Void
    private let onWelcomeReset: @MainActor () -> Void
    private let approvedSuffixes: [String]

    public init(
        simulator: CapabilitySimulator?,
        onboarding: OnboardingStore,
        approvedSuffixes: [String],
        onChange: @escaping @MainActor () async -> Void,
        onWelcomeReset: @escaping @MainActor () -> Void
    ) {
        self.simulator = simulator
        self.onboarding = onboarding
        self.approvedSuffixes = approvedSuffixes
        self.onChange = onChange
        self.onWelcomeReset = onWelcomeReset
    }

    public var hasSimulator: Bool { simulator != nil }

    public func load() async {
        guard let simulator else { return }
        let extras = await simulator.grantedExtras()
        ownerGranted = extras.contains(.owner)
        adminGranted = extras.contains(.admin)
    }

    public func setGranted(_ context: UserContext, _ isGranted: Bool) {
        Task {
            await simulator?.setGranted(context, isGranted)
            await load()
            await onChange()
        }
    }

    public func resetOnboarding() {
        Task {
            await onboarding.reset()
            await onChange()
            onWelcomeReset()
        }
    }

    /// Cada línea es un host de la captura (mitmproxy). La condición: 0 peticiones a `*.litix.io` ni a dominios no
    /// aprobados (ADR-IOS-0029). Esto evalúa una captura; la captura en sí es externa a la app.
    public func evaluateCapture() {
        let hosts =
            capturedHosts
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        violations = NetworkEvidence.violations(hosts: hosts, approvedSuffixes: approvedSuffixes)
    }
}
