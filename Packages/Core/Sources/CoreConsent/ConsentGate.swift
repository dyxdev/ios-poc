import CoreModel
import Foundation

/// Dónde se guarda el consentimiento (UserDefaults solo para preferencias no sensibles, ADR-IOS-0006).
public protocol ConsentStore: Sendable {
    func read() async -> Bool
    func write(_ granted: Bool) async
}

/// Puerta de consentimiento de analítica (ADR-IOS-0014 y 0026). Denegado por defecto y leído en cada uso.
/// En iOS gobierna PostHog y Crashlytics; Mux Data no existe (ADR-IOS-0029). El consentimiento es de la persona:
/// se retira al cerrar sesión (decisión de Andy, 2026-10-16, paridad con ADR-AND-0033).
public actor ConsentGate {
    private let store: ConsentStore
    private let broadcaster = Broadcaster<Bool>(false)

    public init(store: ConsentStore) {
        self.store = store
    }

    /// Lee la preferencia guardada. Hasta que se llama, el consentimiento es «denegado».
    public func load() async {
        let stored = await store.read()
        await broadcaster.send(stored)
    }

    public var isGranted: Bool {
        get async { await broadcaster.current }
    }

    public func setGranted(_ granted: Bool) async {
        await store.write(granted)
        await broadcaster.send(granted)
    }

    public func updates() async -> AsyncStream<Bool> {
        await broadcaster.updates()
    }
}
