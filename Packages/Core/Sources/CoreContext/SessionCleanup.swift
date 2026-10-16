import CoreIdentity
import Foundation

/// Un paso de la limpieza al cerrar sesión (guardados, contexto, consentimiento, cachés de imágenes, subidas, baja
/// del token de push…). Cada paso es independiente y de mejor esfuerzo.
public struct CleanupStep: Sendable {
    public let name: String
    public let run: @Sendable () async throws -> Void

    public init(name: String, run: @escaping @Sendable () async throws -> Void) {
        self.name = name
        self.run = run
    }
}

/// Limpia lo que es de la persona en cuanto la sesión pasa de iniciada a cerrada, sea cual sea la causa (botón,
/// caducidad, cierre desde otra pantalla): está en un solo sitio para que ningún camino de cierre se la salte
/// (ADR-IOS-0007, 0006, 0022 y 0024; paridad con ADR-AND-0034). No actúa al arrancar (desconocida → cerrada): ahí no
/// había persona.
public actor SessionCleanup {
    private let steps: [CleanupStep]
    private var previous: IdentityStatus

    public init(steps: [CleanupStep], initialStatus: IdentityStatus = .unknown) {
        self.steps = steps
        previous = initialStatus
    }

    /// Anota el estado nuevo y, si es la transición iniciada → cerrada, ejecuta los pasos. Devuelve los nombres de
    /// los pasos que fallaron (un fallo no impide los demás).
    @discardableResult
    public func observe(_ status: IdentityStatus) async -> [String] {
        let wasSignedIn = previous == .signedIn
        previous = status
        guard wasSignedIn, status == .signedOut else { return [] }
        var failed: [String] = []
        for step in steps {
            do {
                try await step.run()
            } catch {
                failed.append(step.name)
            }
        }
        return failed
    }

    public func watch(_ states: AsyncStream<IdentityState>) async {
        for await state in states {
            await observe(state.status)
        }
    }
}
