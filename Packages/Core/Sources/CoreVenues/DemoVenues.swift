import CoreModel
import Foundation

/// Datos de EJEMPLO, ficticios: nombres, precios, capacidades y valoraciones no son reales.
/// Las fotos son las de Unsplash que ya usa la web del PoC (licencia libre) y los vídeos, los dos playback IDs
/// públicos de Mux del catálogo de la web (solo de demostración: en producción todo vídeo lleva token firmado).
public enum DemoVenues {
    private static func photo(_ id: String) -> URL {
        // Los literales de abajo son constantes del código: una URL mal escrita se vería en las pruebas.
        guard let url = URL(string: "https://images.unsplash.com/photo-\(id)") else {
            preconditionFailure("URL de foto de ejemplo inválida: \(id)")
        }
        return url
    }

    private static let garden = photo("1696204868903-91d809b4df09")
    private static let loft = photo("1779300007516-eebee9151c19")
    private static let villa = photo("1543489822-c49534f3271f")
    private static let weddings = photo("1708569176850-9de9aa6b179b")
    private static let corporate = photo("1540575467063-178a50c2df87")
    private static let shoots = photo("1647427854253-b92bb40c9330")
    private static let birthdays = photo("1530103862676-de8c9debad1d")
    private static let meetings = photo("1716703435453-a7733d600d68")
    private static let popups = photo("1766384093125-f00a4eb8a392")

    private static let tourOne = "EcHgOK9coz5K4rjSwOkoE7Y7O01201YMIC200RI6lNxnhs"
    private static let tourTwo = "DS00Spx1CV902MCtPj5WknGlR102V5HFkDe"

    public static let all: [Venue] = [
        Venue(
            id: "jardin-acacias",
            name: "Jardín de las Acacias",
            city: "Sevilla",
            category: .weddings,
            capacity: 180,
            pricePerDay: 1450,
            rating: 4.9,
            reviewCount: 212,
            photos: [garden, villa, weddings],
            tourPlaybackID: tourOne,
            isAvailable: true,
            isFeatured: true
        ),
        Venue(
            id: "loft-gracia",
            name: "Loft Industrial Gràcia",
            city: "Barcelona",
            category: .shoots,
            capacity: 60,
            pricePerDay: 620,
            rating: 4.8,
            reviewCount: 96,
            photos: [loft, shoots, meetings],
            tourPlaybackID: tourTwo,
            isAvailable: true,
            isFeatured: true
        ),
        Venue(
            id: "villa-mirador",
            name: "Villa Mirador",
            city: "Málaga",
            category: .weddings,
            capacity: 120,
            pricePerDay: 2100,
            rating: 4.9,
            reviewCount: 143,
            photos: [villa, garden, birthdays],
            tourPlaybackID: tourOne,
            isAvailable: false,
            isFeatured: true
        ),
        Venue(
            id: "salon-aurora",
            name: "Salón Aurora",
            city: "Madrid",
            category: .weddings,
            capacity: 240,
            pricePerDay: 1900,
            rating: 4.7,
            reviewCount: 310,
            photos: [weddings, garden, corporate],
            tourPlaybackID: tourTwo,
            isAvailable: true,
            isFeatured: false
        ),
        Venue(
            id: "auditorio-norte",
            name: "Auditorio Norte",
            city: "Bilbao",
            category: .corporate,
            capacity: 400,
            pricePerDay: 2800,
            rating: 4.6,
            reviewCount: 88,
            photos: [corporate, meetings, loft],
            tourPlaybackID: nil,
            isAvailable: true,
            isFeatured: false
        ),
        Venue(
            id: "estudio-cenital",
            name: "Estudio Cenital",
            city: "Valencia",
            category: .shoots,
            capacity: 30,
            pricePerDay: 380,
            rating: 4.8,
            reviewCount: 64,
            photos: [shoots, loft, popups],
            tourPlaybackID: nil,
            isAvailable: false,
            isFeatured: false
        ),
        Venue(
            id: "terraza-confeti",
            name: "Terraza Confeti",
            city: "Madrid",
            category: .birthdays,
            capacity: 80,
            pricePerDay: 540,
            rating: 4.5,
            reviewCount: 57,
            photos: [birthdays, garden, weddings],
            tourPlaybackID: nil,
            isAvailable: true,
            isFeatured: false
        ),
        Venue(
            id: "sala-atlas",
            name: "Sala Atlas",
            city: "Barcelona",
            category: .meetings,
            capacity: 24,
            pricePerDay: 210,
            rating: 4.7,
            reviewCount: 121,
            photos: [meetings, corporate, loft],
            tourPlaybackID: nil,
            isAvailable: true,
            isFeatured: false
        ),
        Venue(
            id: "nave-poblenou",
            name: "Nave Pop-up Poblenou",
            city: "Barcelona",
            category: .popups,
            capacity: 150,
            pricePerDay: 760,
            rating: 4.4,
            reviewCount: 39,
            photos: [popups, loft, shoots],
            tourPlaybackID: nil,
            isAvailable: true,
            isFeatured: false
        ),
    ]
}
