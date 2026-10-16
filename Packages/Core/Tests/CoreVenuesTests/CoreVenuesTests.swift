import CoreModel
import CoreTesting
import Foundation
import Testing

@testable import CoreVenues

struct DemoVenuesTests {
    @Test func catalogIsConsistent() {
        let all = DemoVenues.all
        #expect(all.count == 9)
        #expect(Set(all.map(\.id)).count == all.count)
        #expect(all.allSatisfy { !$0.photos.isEmpty })
        #expect(all.filter(\.isFeatured).count == 3)
        #expect(all.filter { $0.tourPlaybackID != nil }.count == 4)
    }

    @Test func repositoryFindsByID() async {
        let repository = DemoVenueRepository(latency: .zero)
        #expect(await repository.venue(id: "loft-gracia")?.city == "Barcelona")
        #expect(await repository.venue(id: "no-existe") == nil)
        #expect(await repository.venues().count == 9)
    }
}

struct VenueFilterTests {
    private let venues = DemoVenues.all

    @Test func searchMatchesNameOrCityIgnoringCaseAndAccents() {
        #expect(VenueFilter.apply(venues, query: "  barcelona ", category: nil).map(\.id).contains("loft-gracia"))
        #expect(VenueFilter.apply(venues, query: "AURORA", category: nil).map(\.id) == ["salon-aurora"])
        #expect(VenueFilter.apply(venues, query: "malaga", category: nil).map(\.id) == ["villa-mirador"])
    }

    @Test func categoryAndQueryCombine() {
        let result = VenueFilter.apply(venues, query: "madrid", category: .weddings)
        #expect(result.map(\.id) == ["salon-aurora"])
    }

    @Test func pressingTheActiveCategoryClearsIt() {
        #expect(VenueFilter.toggle(.weddings, current: nil) == .weddings)
        #expect(VenueFilter.toggle(.weddings, current: .weddings) == nil)
        #expect(VenueFilter.toggle(.shoots, current: .weddings) == .shoots)
    }

    @Test func isFilteringOnlyWithTextOrCategory() {
        #expect(!VenueFilter.isFiltering(query: "   ", category: nil))
        #expect(VenueFilter.isFiltering(query: "x", category: nil))
        #expect(VenueFilter.isFiltering(query: "", category: .popups))
    }
}

struct FormattersTests {
    // El separador (punto, coma o espacio fino) cambia entre ICU de Linux y de Apple: se comprueban los dígitos.
    @Test func priceHasNoDecimalsAndTheEuroSign() {
        for locale in [Locale(identifier: "es_ES"), Locale(identifier: "en_US")] {
            let text = Formatters.price(1450, locale: locale)
            #expect(text.contains("€"))
            #expect(text.filter(\.isNumber) == "1450")
        }
    }

    @Test func ratingKeepsOneDecimalAndTheReviewCount() {
        let spanish = Formatters.rating(4.9, reviewCount: 212, locale: Locale(identifier: "es_ES"))
        let english = Formatters.rating(4.9, reviewCount: 212, locale: Locale(identifier: "en_US"))
        #expect(spanish == "4,9 (212)")
        #expect(english == "4.9 (212)")
    }
}

struct SavedVenuesTests {
    @Test func toggleAddsAndRemovesAndClearEmpties() async {
        let saved = SavedVenues()
        await saved.toggle("loft-gracia")
        #expect(await saved.ids == ["loft-gracia"])
        await saved.toggle("loft-gracia")
        #expect(await saved.ids.isEmpty)
        await saved.toggle("a")
        await saved.toggle("b")
        await saved.clear()
        #expect(await saved.ids.isEmpty)
    }
}
