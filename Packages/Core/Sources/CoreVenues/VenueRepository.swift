import CoreModel
import Foundation

/// Fuente de venues de la app. Hoy solo hay datos de ejemplo; la API de venues la sustituirá sin cambiar
/// a los consumidores. Un protocolo para poder usar fakes (ADR-IOS-0015).
public protocol VenueRepository: Sendable {
    func venues() async -> [Venue]
    func venue(id: String) async -> Venue?
}

/// Venues de ejemplo con una latencia simulada para ver los estados de carga.
public struct DemoVenueRepository: VenueRepository {
    private let latency: Duration

    public init(latency: Duration = .milliseconds(700)) {
        self.latency = latency
    }

    public func venues() async -> [Venue] {
        if latency > .zero {
            try? await Task.sleep(for: latency)
        }
        return DemoVenues.all
    }

    /// Sin latencia: el detalle ya conoce el venue por la lista y la transición no debe esperar.
    public func venue(id: String) async -> Venue? {
        DemoVenues.all.first { $0.id == id }
    }
}
