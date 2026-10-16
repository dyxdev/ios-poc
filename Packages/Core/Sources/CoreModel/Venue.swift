import Foundation

/// Un venue tal como lo ve la app. Datos de ejemplo hasta que exista la API de venues.
public struct Venue: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let name: String
    public let city: String
    public let category: VenueCategory
    public let capacity: Int
    /// Euros por día.
    public let pricePerDay: Int
    public let rating: Double
    public let reviewCount: Int
    /// La primera es la portada.
    public let photos: [URL]
    /// Playback ID de Mux del vídeo tour, si lo tiene.
    public let tourPlaybackID: String?
    public let isAvailable: Bool
    public let isFeatured: Bool

    public init(
        id: String,
        name: String,
        city: String,
        category: VenueCategory,
        capacity: Int,
        pricePerDay: Int,
        rating: Double,
        reviewCount: Int,
        photos: [URL],
        tourPlaybackID: String?,
        isAvailable: Bool,
        isFeatured: Bool
    ) {
        // La interfaz da por hecho que hay portada: un venue sin fotos falla aquí, no con un cierre en una tarjeta.
        precondition(!photos.isEmpty, "Un venue necesita al menos una foto")
        self.id = id
        self.name = name
        self.city = city
        self.category = category
        self.capacity = capacity
        self.pricePerDay = pricePerDay
        self.rating = rating
        self.reviewCount = reviewCount
        self.photos = photos
        self.tourPlaybackID = tourPlaybackID
        self.isAvailable = isAvailable
        self.isFeatured = isFeatured
    }

    public var cover: URL { photos[0] }
}
