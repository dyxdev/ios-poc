import CoreConsent
import CoreModel
import CorePlayback
import CoreVenues
import Foundation
import Observation

/// Estado del detalle de un venue. Sin SwiftUI: se prueba aparte. El vídeo del tour usa AVPlayer propio con la URL de
/// Mux (ADR-IOS-0029): sin Mux Player ni Mux Data, así que el consentimiento aquí solo se muestra (gobierna PostHog y
/// Crashlytics) y nada de la reproducción depende de él.
@MainActor
@Observable
public final class DetailModel {
    public enum Phase: Equatable {
        case loading
        case notFound
        case content(Venue)
    }

    public private(set) var phase: Phase = .loading
    public private(set) var isSaved = false
    public private(set) var analyticsConsent = false
    public var showsReserveNotice = false

    private let venueID: String
    private let repository: VenueRepository
    private let saved: SavedVenues
    private let consent: ConsentGate

    public init(venueID: String, repository: VenueRepository, saved: SavedVenues, consent: ConsentGate) {
        self.venueID = venueID
        self.repository = repository
        self.saved = saved
        self.consent = consent
    }

    public func load() async {
        if let venue = await repository.venue(id: venueID) {
            phase = .content(venue)
        } else {
            phase = .notFound
        }
    }

    public func observeSaved() async {
        for await ids in await saved.updates() {
            isSaved = ids.contains(venueID)
        }
    }

    public func observeConsent() async {
        for await granted in await consent.updates() {
            analyticsConsent = granted
        }
    }

    public func toggleSaved() {
        Task { await saved.toggle(venueID) }
    }

    /// URL HLS del tour. Los playback IDs de la demostración son públicos (sin token); en producción todo vídeo del
    /// catálogo lleva token firmado emitido por la API (decisión D12 de Andy, 2026-10-16).
    public func tourURL(for venue: Venue) -> URL? {
        venue.tourPlaybackID.flatMap { SignedPlaybackURL.make(playbackID: $0, token: nil) }
    }

    public func reserveTapped() {
        showsReserveNotice = true
    }
}
