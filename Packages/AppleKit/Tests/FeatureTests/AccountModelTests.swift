import CoreConsent
import CoreContext
import CoreIdentity
import CoreTesting
import CoreVenues
import Foundation
import Testing

@testable import FeatureAccount
@testable import FeatureOwner

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func tokens() -> Tokens {
    Tokens(accessToken: "a", refreshToken: "r", idToken: "i", expiresAt: t0.addingTimeInterval(3600))
}

/// Anota las llamadas de los cierres que la app inyecta.
@MainActor
private final class Calls {
    var signIns: [String?] = []
    var signOuts = 0
}

@MainActor
private func makeAccount(
    stored: Tokens? = nil,
    calls: Calls,
    consent: ConsentGate = ConsentGate(store: InMemoryConsentStore())
) -> (AccountModel, IdentityManager) {
    let identity = IdentityManager(
        backend: FakeAuthBackend(refreshResult: .success(tokens())),
        store: InMemoryTokenStore(stored),
        now: { t0 }
    )
    let model = AccountModel(
        identityManager: identity,
        consent: consent,
        signIn: { calls.signIns.append($0) },
        signOut: { calls.signOuts += 1 }
    )
    return (model, identity)
}

@MainActor
struct AccountModelTests {
    @Test func aStoredSessionShowsAsSignedInWithAnExpiryText() async {
        let calls = Calls()
        let (model, identity) = makeAccount(stored: tokens(), calls: calls)
        let observer = Task { await model.observeIdentity() }
        defer { observer.cancel() }
        await identity.restore()
        #expect(await eventually { await model.isSignedIn })
        #expect(model.expiryText(locale: Locale(identifier: "en_US")) != nil)
    }

    @Test func withoutASessionThereIsNoExpiryText() async {
        let (model, identity) = makeAccount(calls: Calls())
        let observer = Task { await model.observeIdentity() }
        defer { observer.cancel() }
        await identity.restore()
        #expect(await eventually { await model.identity.status == .signedOut })
        #expect(!model.isSignedIn)
        #expect(model.expiryText(locale: Locale(identifier: "en_US")) == nil)
    }

    @Test func signInPassesTheGoogleHintOnlyWhenAsked() async {
        let calls = Calls()
        let (model, _) = makeAccount(calls: calls)
        model.signIn()
        model.signIn(idpHint: "google")
        #expect(await eventually { await calls.signIns.count == 2 })
        #expect(calls.signIns == [nil, "google"])
    }

    @Test func signOutCallsTheInjectedClosure() async {
        let calls = Calls()
        let (model, _) = makeAccount(calls: calls)
        model.signOut()
        #expect(await eventually { await calls.signOuts == 1 })
    }

    @Test func theConsentSwitchWritesToTheGateAndTheModelFollowsIt() async {
        let gate = ConsentGate(store: InMemoryConsentStore())
        let (model, _) = makeAccount(calls: Calls(), consent: gate)
        let observer = Task { await model.observeConsent() }
        defer { observer.cancel() }
        model.setAnalyticsConsent(true)
        #expect(await eventually { await model.analyticsConsent })
        #expect(await gate.isGranted)
        model.setAnalyticsConsent(false)
        #expect(await eventually { await !model.analyticsConsent })
    }

    @Test func everyIdentityErrorHasADistinctTextInTheCatalog() {
        let errors: [IdentityError] = [.notConfigured, .canceled, .sessionExpired, .network, .failed]
        let keys = errors.map(\.messageKey)
        #expect(Set(keys).count == errors.count)
    }
}

@MainActor
struct WelcomeModelTests {
    private func makeWelcome(identity: IdentityManager, onboarding: OnboardingStore, calls: Calls) -> WelcomeModel {
        WelcomeModel(
            repository: DemoVenueRepository(latency: .zero),
            identityManager: identity,
            onboarding: onboarding,
            signIn: { calls.signIns.append($0) }
        )
    }

    private func makeIdentity(stored: Tokens? = nil) -> IdentityManager {
        IdentityManager(
            backend: FakeAuthBackend(refreshResult: .success(tokens())),
            store: InMemoryTokenStore(stored),
            now: { t0 }
        )
    }

    @Test func theCollageUsesTheCoversOfThreeFeaturedVenues() async {
        let model = makeWelcome(identity: makeIdentity(), onboarding: InMemoryOnboardingStore(), calls: Calls())
        await model.loadCovers()
        #expect(model.covers?.count == 3)
    }

    @Test func aRestoredSessionDoesNotSkipTheWelcome() async {
        let identity = makeIdentity(stored: tokens())
        let model = makeWelcome(identity: identity, onboarding: InMemoryOnboardingStore(), calls: Calls())
        let observer = Task { await model.observeIdentity() }
        defer { observer.cancel() }
        await identity.restore()
        #expect(await eventually { await model.identity.status == .signedIn })
        #expect(!model.shouldFinishAfterSignIn)
        #expect(!model.showsSignIn)
    }

    @Test func aLoginRequestedFromTheWelcomeFinishesItWhenTheSessionStarts() async throws {
        let identity = makeIdentity()
        let calls = Calls()
        let model = makeWelcome(identity: identity, onboarding: InMemoryOnboardingStore(), calls: calls)
        let observer = Task { await model.observeIdentity() }
        defer { observer.cancel() }
        await identity.restore()
        model.requestSignIn()
        #expect(await eventually { await calls.signIns.count == 1 })
        try await identity.completeSignIn(tokens())
        #expect(await eventually { await model.shouldFinishAfterSignIn })
    }

    @Test func prepareToShowForgetsAPreviousLoginRequest() async {
        let model = makeWelcome(identity: makeIdentity(), onboarding: InMemoryOnboardingStore(), calls: Calls())
        model.requestSignIn()
        #expect(model.signInRequested)
        model.prepareToShow()
        #expect(!model.signInRequested)
    }

    @Test func markSeenIsStoredOnTheDevice() async {
        let onboarding = InMemoryOnboardingStore()
        let model = makeWelcome(identity: makeIdentity(), onboarding: onboarding, calls: Calls())
        await model.markSeen()
        #expect(await onboarding.welcomeSeen())
    }
}

@MainActor
struct DiagnosticsModelTests {
    private func makeModel(
        simulator: CapabilitySimulator? = SimulatedCapabilities(),
        onboarding: OnboardingStore = InMemoryOnboardingStore(),
        resets: Calls = Calls()
    ) -> DiagnosticsModel {
        DiagnosticsModel(
            simulator: simulator,
            onboarding: onboarding,
            approvedSuffixes: ["mux.com", "idp.example.test"],
            onChange: {},
            onWelcomeReset: { resets.signOuts += 1 }
        )
    }

    @Test func aCaptureWithLitixFailsAndNamesTheHost() {
        let model = makeModel()
        model.capturedHosts = "stream.mux.com\nimage.mux.com\nfoo.litix.io\n"
        model.evaluateCapture()
        #expect(model.violations == ["foo.litix.io"])
    }

    @Test func aCleanCapturePassesAndAnUnapprovedHostFails() {
        let model = makeModel()
        model.capturedHosts = "stream.mux.com\n  idp.example.test  \n\n"
        model.evaluateCapture()
        #expect(model.violations == [])
        model.capturedHosts = "stream.mux.com\ntracker.example.org"
        model.evaluateCapture()
        #expect(model.violations == ["tracker.example.org"])
    }

    @Test func beforeEvaluatingThereIsNoVerdict() {
        #expect(makeModel().violations == nil)
    }

    @Test func theSimulatorTogglesOwnerAndAdmin() async {
        let model = makeModel()
        await model.load()
        #expect(model.ownerGranted)
        #expect(!model.adminGranted)
        model.setGranted(.admin, true)
        #expect(await eventually { await model.adminGranted })
        model.setGranted(.owner, false)
        #expect(await eventually { await !model.ownerGranted })
    }

    @Test func withoutASimulatorThereIsNothingToToggle() {
        #expect(!makeModel(simulator: nil).hasSimulator)
    }

    @Test func resettingTheOnboardingClearsItAndAsksTheRootToShowTheWelcome() async {
        let onboarding = InMemoryOnboardingStore(seen: true)
        let resets = Calls()
        let model = makeModel(onboarding: onboarding, resets: resets)
        model.resetOnboarding()
        #expect(await eventually { await resets.signOuts == 1 })
        #expect(!(await onboarding.welcomeSeen()))
    }
}

@MainActor
struct OwnerModelTests {
    @Test func showsTwoSampleVenuesAndLoadsOnlyOnce() async {
        let model = OwnerModel(repository: DemoVenueRepository(latency: .zero))
        #expect(model.venues == nil)
        await model.load()
        #expect(model.venues?.count == 2)
        let first = model.venues
        await model.load()
        #expect(model.venues == first)
    }
}
