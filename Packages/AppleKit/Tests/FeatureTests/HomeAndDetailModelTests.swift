import CoreConsent
import CoreTesting
import CoreVenues
import Testing

@testable import FeatureDetail
@testable import FeatureHome

@MainActor
struct HomeModelTests {
    private func makeModel() -> (HomeModel, SavedVenues) {
        let saved = SavedVenues()
        return (HomeModel(repository: DemoVenueRepository(latency: .zero), saved: saved), saved)
    }

    @Test func loadsTheCatalogOnceAndStopsLoading() async {
        let (model, _) = makeModel()
        #expect(model.isLoading)
        await model.load()
        #expect(!model.isLoading)
        let expectedCount = DemoVenues.all.count
        #expect(model.allVenues.count == expectedCount)
        let everyFeaturedIsMarked = model.featured.allSatisfy { $0.isFeatured }
        #expect(everyFeaturedIsMarked)
    }

    @Test func searchAndCategoryFilterTheResultsAndClearRestoresThem() async {
        let (model, _) = makeModel()
        await model.load()
        model.query = "barcelona"
        #expect(!model.results.isEmpty)
        #expect(model.results.allSatisfy { $0.city == "Barcelona" })
        #expect(model.isFiltering)
        model.toggleCategory(.weddings)
        #expect(model.results.allSatisfy { $0.city == "Barcelona" && $0.category == .weddings })
        model.clearFilters()
        #expect(!model.isFiltering)
        #expect(model.results.count == model.allVenues.count)
    }

    @Test func tappingTheActiveCategoryAgainRemovesIt() async {
        let (model, _) = makeModel()
        model.toggleCategory(.shoots)
        #expect(model.category == .shoots)
        model.toggleCategory(.shoots)
        #expect(model.category == nil)
    }

    @Test func savingAVenueIsReflectedInTheModel() async {
        let (model, _) = makeModel()
        let observer = Task { await model.observeSaved() }
        defer { observer.cancel() }
        model.toggleSaved("loft-gracia")
        #expect(await eventually { await model.savedIDs.contains("loft-gracia") })
        model.toggleSaved("loft-gracia")
        #expect(await eventually { await model.savedIDs.isEmpty })
    }
}

@MainActor
struct DetailModelTests {
    private func makeModel(
        id: String,
        consent: ConsentGate = ConsentGate(store: InMemoryConsentStore())
    ) -> DetailModel {
        DetailModel(
            venueID: id,
            repository: DemoVenueRepository(latency: .zero),
            saved: SavedVenues(),
            consent: consent
        )
    }

    @Test func aKnownVenueLoadsItsContent() async {
        let model = makeModel(id: "jardin-acacias")
        await model.load()
        guard case let .content(venue) = model.phase else {
            Issue.record("Se esperaba contenido")
            return
        }
        #expect(venue.id == "jardin-acacias")
    }

    @Test func anUnknownVenueShowsNotFound() async {
        let model = makeModel(id: "no-existe")
        await model.load()
        #expect(model.phase == .notFound)
    }

    @Test func theTourURLOnlyExistsForVenuesWithAVideo() async throws {
        let withTour = try #require(await DemoVenueRepository(latency: .zero).venue(id: "jardin-acacias"))
        let without = try #require(await DemoVenueRepository(latency: .zero).venue(id: "sala-atlas"))
        let model = makeModel(id: withTour.id)
        let url = try #require(model.tourURL(for: withTour))
        #expect(url.host == "stream.mux.com")
        #expect(model.tourURL(for: without) == nil)
    }

    @Test func theConsentIsShownButNeverRequiredForPlayback() async {
        let gate = ConsentGate(store: InMemoryConsentStore())
        let model = makeModel(id: "jardin-acacias", consent: gate)
        let observer = Task { await model.observeConsent() }
        defer { observer.cancel() }
        #expect(!model.analyticsConsent)
        await gate.setGranted(true)
        #expect(await eventually { await model.analyticsConsent })
    }

    @Test func reserveShowsTheNotice() async {
        let model = makeModel(id: "jardin-acacias")
        model.reserveTapped()
        #expect(model.showsReserveNotice)
    }
}
