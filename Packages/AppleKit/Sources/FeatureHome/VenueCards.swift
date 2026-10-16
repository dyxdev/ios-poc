#if canImport(SwiftUI)
    import AppStrings
    import CoreModel
    import CoreVenues
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Datos de una tarjeta ya formateados: así la vista no calcula nada (ADR-IOS-0002).
    struct VenueCardText {
        let venue: Venue
        let locale: Locale

        var capacity: String { AppStrings.format("venue.capacity", venue.capacity) }
        var subtitle: String { "\(venue.city) · \(capacity)" }
        var rating: String { Formatters.rating(venue.rating, reviewCount: venue.reviewCount, locale: locale) }
        var price: String {
            AppStrings.format("venue.price.perday", Formatters.price(venue.pricePerDay, locale: locale))
        }
        var availability: String { AppStrings.text(venue.isAvailable ? "venue.available" : "venue.unavailable") }
        var photoDescription: String { AppStrings.format("venue.photo", venue.name) }
        var saveLabel: String { AppStrings.format("venue.save", venue.name) }
        var unsaveLabel: String { AppStrings.format("venue.unsave", venue.name) }
    }

    struct VenueSummary: View {
        let text: VenueCardText

        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(verbatim: text.venue.name).font(.outfit(.headline)).foregroundStyle(Theme.text)
                Text(verbatim: text.subtitle).font(.outfit(.caption)).foregroundStyle(Theme.textMuted)
                RatingLabel(text: text.rating)
                HStack(spacing: Spacing.md) {
                    Text(verbatim: text.price).font(.outfit(.label)).foregroundStyle(Theme.success)
                    AvailabilityLabel(text: text.availability, isAvailable: text.venue.isAvailable)
                }
            }
        }
    }

    /// Destacado del carrusel: tira de tres fotos (una grande y dos pequeñas) sobre los datos. 12 pt solo aquí.
    struct FeaturedVenueCard: View {
        let venue: Venue
        let isSaved: Bool
        let onOpen: (String) -> Void
        let onToggleSaved: () -> Void
        @Environment(\.locale) private var locale
        @Environment(\.displayScale) private var displayScale

        private var key: String { "featured-\(venue.id)" }

        var body: some View {
            let text = VenueCardText(venue: venue, locale: locale)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                strip(text)
                HStack(alignment: .center) {
                    VenueSummary(text: text)
                    Spacer(minLength: 0)
                    SaveButton(
                        isSaved: isSaved,
                        label: isSaved ? text.unsaveLabel : text.saveLabel,
                        action: onToggleSaved
                    )
                }
            }
            .padding(Spacing.sm)
            .frame(width: 280)
            .cardStyle(radius: Radius.featured)
            .contentShape(Rectangle())
            .onTapGesture { onOpen(key) }
            .zoomSource(id: key)
            .accessibilityElement(children: .contain)
        }

        private func strip(_ text: VenueCardText) -> some View {
            HStack(spacing: Spacing.xs) {
                photo(venue.photos[0], points: 180, description: text.photoDescription)
                    .frame(width: 168)
                VStack(spacing: Spacing.xs) {
                    ForEach(Array(venue.photos.dropFirst().prefix(2)), id: \.self) { url in
                        photo(url, points: 90, description: nil)
                    }
                }
            }
            .frame(height: 112)
            .clipShape(RoundedRectangle(cornerRadius: Radius.standard))
        }

        private func photo(_ url: URL, points: Double, description: String?) -> some View {
            VenueImage(
                url: RenditionURL.make(for: url, points: points, scale: displayScale),
                accessibilityText: description
            )
            .clipped()
        }
    }

    /// Tarjeta de la lista: miniatura cuadrada, datos y corazón. Compacta (8 pt).
    struct VenueListCard: View {
        let venue: Venue
        let isSaved: Bool
        let onOpen: (String) -> Void
        let onToggleSaved: () -> Void
        @Environment(\.locale) private var locale
        @Environment(\.displayScale) private var displayScale

        private var key: String { "list-\(venue.id)" }

        var body: some View {
            let text = VenueCardText(venue: venue, locale: locale)
            HStack(spacing: Spacing.md) {
                VenueImage(
                    url: RenditionURL.make(for: venue.cover, points: 104, scale: displayScale),
                    accessibilityText: text.photoDescription
                )
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: Radius.standard))
                VenueSummary(text: text)
                Spacer(minLength: 0)
                SaveButton(isSaved: isSaved, label: isSaved ? text.unsaveLabel : text.saveLabel, action: onToggleSaved)
            }
            .padding(Spacing.sm)
            .cardStyle()
            .contentShape(Rectangle())
            .onTapGesture { onOpen(key) }
            .zoomSource(id: key)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isButton)
        }
    }

    /// Esqueletos con la misma forma que las tarjetas, para que la carga no mueva el contenido.
    struct VenueSkeleton: View {
        let featured: Bool

        var body: some View {
            if featured {
                ShimmerBox().frame(width: 280, height: 180).clipShape(RoundedRectangle(cornerRadius: Radius.featured))
            } else {
                ShimmerBox().frame(height: 120).clipShape(RoundedRectangle(cornerRadius: Radius.standard))
            }
        }
    }
#endif
