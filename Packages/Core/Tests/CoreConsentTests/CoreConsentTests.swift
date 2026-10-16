import CoreTesting
import Testing

@testable import CoreConsent

struct ConsentGateTests {
    @Test func isDeniedByDefaultEvenBeforeLoading() async {
        let gate = ConsentGate(store: InMemoryConsentStore(true))
        #expect(await gate.isGranted == false)
    }

    @Test func loadReadsTheStoredPreference() async {
        let gate = ConsentGate(store: InMemoryConsentStore(true))
        await gate.load()
        #expect(await gate.isGranted)
    }

    @Test func setGrantedPersistsAndNotifies() async {
        let store = InMemoryConsentStore(false)
        let gate = ConsentGate(store: store)
        var iterator = await gate.updates().makeAsyncIterator()
        #expect(await iterator.next() == false)
        await gate.setGranted(true)
        #expect(await iterator.next() == true)
        #expect(await store.read())
    }
}

struct AnalyticsCoordinatorTests {
    @Test func neverStartsTheSDKWithoutConsent() async {
        let gate = ConsentGate(store: InMemoryConsentStore(false))
        let sdk = FakeAnalyticsSDK()
        let coordinator = AnalyticsCoordinator(gate: gate, sdk: sdk)
        let task = Task { await coordinator.run() }
        try? await Task.sleep(for: .milliseconds(150))
        #expect(await sdk.startCount == 0)
        task.cancel()
    }

    @Test func startsOnceWhenGrantedAndStopsAndResetsWhenWithdrawn() async {
        let gate = ConsentGate(store: InMemoryConsentStore(false))
        let sdk = FakeAnalyticsSDK()
        let coordinator = AnalyticsCoordinator(gate: gate, sdk: sdk)
        let task = Task { await coordinator.run() }
        await gate.setGranted(true)
        #expect(await eventually { await sdk.startCount == 1 })
        await gate.setGranted(true)
        try? await Task.sleep(for: .milliseconds(100))
        #expect(await sdk.startCount == 1)
        await gate.setGranted(false)
        #expect(await eventually { await sdk.stopCount == 1 })
        #expect(await sdk.resetCount == 1)
        task.cancel()
    }
}

struct EventTaxonomyTests {
    private let taxonomy = EventTaxonomy(allowedEvents: ["venue_viewed", "venue_saved"])

    @Test func acceptsAllowedEventsWithoutPersonalData() {
        #expect(taxonomy.validate(event: "venue_viewed", properties: ["venue_id": "x"]).isEmpty)
    }

    @Test func rejectsUnknownEventsAndPersonalDataKeys() {
        let violations = taxonomy.validate(event: "login", properties: ["Email": "a@b.c", "venue_id": "x"])
        #expect(violations.contains(.unknownEvent("login")))
        #expect(violations.contains(.personalData(property: "Email")))
    }
}
