import CoreModel
import CoreVenues
import Foundation
import Observation

/// Panel de propietario DE EJEMPLO: cifras ficticias y los dos primeros espacios del catálogo. Sirve para ver el
/// cambio de contexto; el panel real llega con la API.
@MainActor
@Observable
public final class OwnerModel {
    public static let samplePendingBookings = 3
    public static let sampleMonthIncome = 4_280
    static let ownedVenues = 2

    public private(set) var venues: [Venue]?

    private let repository: VenueRepository

    public init(repository: VenueRepository) {
        self.repository = repository
    }

    public func load() async {
        guard venues == nil else { return }
        venues = Array(await repository.venues().prefix(Self.ownedVenues))
    }
}
