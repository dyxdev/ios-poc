import CoreModel
import CoreVenues
import Foundation
import Observation

/// Estado de Inicio: catálogo, búsqueda, categoría y guardados (compartidos con el Detalle, en memoria). Sin SwiftUI:
/// la lógica se prueba aparte de las vistas (ADR-IOS-0002 y 0015).
@MainActor
@Observable
public final class HomeModel {
    public private(set) var isLoading = true
    public var query = ""
    public private(set) var category: VenueCategory?
    public private(set) var allVenues: [Venue] = []
    public private(set) var savedIDs: Set<String> = []
    /// Verdadero hasta que se vio la primera entrada escalonada: no se repite al volver a la pestaña.
    public private(set) var playIntro = true

    private let repository: VenueRepository
    private let saved: SavedVenues

    public init(repository: VenueRepository, saved: SavedVenues) {
        self.repository = repository
        self.saved = saved
    }

    public var featured: [Venue] { allVenues.filter(\.isFeatured) }

    public var results: [Venue] { VenueFilter.apply(allVenues, query: query, category: category) }

    public var isFiltering: Bool { VenueFilter.isFiltering(query: query, category: category) }

    public func load() async {
        guard isLoading else { return }
        allVenues = await repository.venues()
        isLoading = false
    }

    public func observeSaved() async {
        for await ids in await saved.updates() {
            savedIDs = ids
        }
    }

    public func toggleCategory(_ selected: VenueCategory?) {
        category = selected.flatMap { VenueFilter.toggle($0, current: category) }
    }

    public func toggleSaved(_ venueID: String) {
        Task { await saved.toggle(venueID) }
    }

    public func clearFilters() {
        query = ""
        category = nil
    }

    public func introPlayed() {
        playIntro = false
    }
}
