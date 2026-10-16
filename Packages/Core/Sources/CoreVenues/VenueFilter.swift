import CoreModel
import Foundation

/// Búsqueda y categoría de Inicio, filtradas en local. La búsqueda mira nombre y ciudad sin distinguir
/// mayúsculas ni acentos; pulsar la categoría activa la quita (`nil` es «Todos»).
public enum VenueFilter {
    public static func apply(_ venues: [Venue], query: String, category: VenueCategory?) -> [Venue] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return venues.filter { venue in
            let textOK =
                text.isEmpty
                || venue.name.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                || venue.city.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            return textOK && (category == nil || venue.category == category)
        }
    }

    public static func toggle(_ selected: VenueCategory, current: VenueCategory?) -> VenueCategory? {
        current == selected ? nil : selected
    }

    public static func isFiltering(query: String, category: VenueCategory?) -> Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || category != nil
    }
}
