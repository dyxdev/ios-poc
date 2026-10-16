import CoreModel
import Foundation

/// Venues guardados (corazón). Inicio y Detalle comparten el mismo estado. Hoy solo en memoria: se pierde al
/// cerrar la app; persistirlos llega con la API (ADR-IOS-0006: SwiftData es solo caché de lectura).
public actor SavedVenues {
    private let broadcaster = Broadcaster<Set<String>>([])

    public init() {}

    public var ids: Set<String> {
        get async { await broadcaster.current }
    }

    public func updates() async -> AsyncStream<Set<String>> {
        await broadcaster.updates()
    }

    public func toggle(_ venueID: String) async {
        var current = await broadcaster.current
        if current.contains(venueID) {
            current.remove(venueID)
        } else {
            current.insert(venueID)
        }
        await broadcaster.send(current)
    }

    /// Al cerrar sesión: los guardados no pasan a la siguiente persona que use el dispositivo.
    public func clear() async {
        await broadcaster.send([])
    }
}
