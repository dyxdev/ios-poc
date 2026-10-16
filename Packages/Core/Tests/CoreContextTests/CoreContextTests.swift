import CoreIdentity
import CoreTesting
import Foundation
import Testing

@testable import CoreContext

struct ContextStateTests {
    @Test func guestOnlyCannotSwitchAndHasNoHint() {
        let state = ContextState.make(available: [.guest], last: nil, seen: [])
        #expect(state.available == [.guest])
        #expect(state.active == .guest)
        #expect(!state.canSwitch)
        #expect(!state.hintPending)
    }

    @Test func anExtraContextStartsAsGuestWithTheHintPending() {
        let state = ContextState.make(available: [.guest, .owner], last: nil, seen: [])
        #expect(state.canSwitch)
        #expect(state.active == .guest)
        #expect(state.hintPending)
    }

    @Test func theLastContextIsKeptOnlyWhileItIsStillAvailable() {
        #expect(ContextState.make(available: [.guest, .owner], last: "owner", seen: []).active == .owner)
        #expect(ContextState.make(available: [.guest], last: "owner", seen: []).active == .guest)
    }

    @Test func contextsAreOrderedGuestOwnerAdmin() {
        let state = ContextState.make(available: [.admin, .guest, .owner], last: nil, seen: [])
        #expect(state.available == [.guest, .owner, .admin])
    }

    @Test func theHintComesBackOnlyForAContextNotSeenBefore() {
        let seenOwner: Set<String> = ["guest", "owner"]
        #expect(!ContextState.make(available: [.guest, .owner], last: nil, seen: seenOwner).hintPending)
        #expect(ContextState.make(available: [.guest, .owner, .admin], last: nil, seen: seenOwner).hintPending)
    }
}

struct ContextManagerTests {
    private let both: Set<UserContext> = [.guest, .owner]

    @Test func selectIsRememberedButIgnoredForAContextThePersonDoesNotHave() async {
        let manager = ContextManager(preferences: InMemoryContextPreferences())
        await manager.select(.owner, available: [.guest])
        #expect(await manager.state(available: [.guest]).active == .guest)
        await manager.select(.owner, available: both)
        #expect(await manager.state(available: both).active == .owner)
    }

    @Test func acknowledgingTheHintClearsItUntilANewContextAppears() async {
        let manager = ContextManager(preferences: InMemoryContextPreferences())
        #expect(await manager.state(available: both).hintPending)
        await manager.acknowledgeHint(available: both)
        #expect(await manager.state(available: both).hintPending == false)
        #expect(await manager.state(available: [.guest, .owner, .admin]).hintPending)
    }

    @Test func aRevokedContextFallsBackToGuestAndComesBackWithoutANewHint() async {
        let manager = ContextManager(preferences: InMemoryContextPreferences())
        await manager.select(.owner, available: both)
        await manager.acknowledgeHint(available: both)
        #expect(await manager.state(available: [.guest]).active == .guest)
        let back = await manager.state(available: both)
        #expect(back.active == .owner)
        #expect(back.hintPending == false)
    }

    @Test func resetForgetsTheLastContextAndTheSeenHints() async {
        let manager = ContextManager(preferences: InMemoryContextPreferences())
        await manager.select(.owner, available: both)
        await manager.acknowledgeHint(available: both)
        await manager.reset()
        let state = await manager.state(available: both)
        #expect(state.active == .guest)
        #expect(state.hintPending)
    }
}

struct CapabilitiesTests {
    @Test func releaseStyleCapabilitiesNeverGrantAnythingButGuest() async {
        let source = GuestOnlyCapabilities()
        #expect(await source.available(signedIn: true) == [.guest])
        #expect(await source.available(signedIn: false) == [.guest])
    }

    #if DEBUG
        @Test func simulatedCapabilitiesGrantOwnerOnlyWithASession() async {
            let simulated = SimulatedCapabilities()
            #expect(await simulated.available(signedIn: false) == [.guest])
            #expect(await simulated.available(signedIn: true) == [.guest, .owner])
        }

        @Test func revokingOwnerRemovesItAndGuestCannotBeRevoked() async {
            let simulated = SimulatedCapabilities()
            await simulated.setGranted(.owner, false)
            await simulated.setGranted(.guest, false)
            #expect(await simulated.available(signedIn: true) == [.guest])
            await simulated.setGranted(.owner, true)
            #expect(await simulated.available(signedIn: true) == [.guest, .owner])
        }

        @Test func theSimulatorControlReportsTheExtrasWithoutGuest() async {
            let simulated = SimulatedCapabilities()
            #expect(await simulated.grantedExtras() == [.owner])
            await simulated.setGranted(.admin, true)
            await simulated.setGranted(.guest, true)
            #expect(await simulated.grantedExtras() == [.owner, .admin])
        }
    #endif
}

private actor Counter {
    private(set) var order: [String] = []
    func record(_ name: String) { order.append(name) }
}

struct SessionCleanupTests {
    private struct Boom: Error {}

    private func makeSteps(_ counter: Counter, failing: String? = nil) -> [CleanupStep] {
        ["saved", "context", "consent", "images", "uploads", "push"].map { name in
            CleanupStep(name: name) {
                await counter.record(name)
                if name == failing { throw Boom() }
            }
        }
    }

    @Test func runsEveryStepWhenTheSessionGoesFromSignedInToSignedOut() async {
        let counter = Counter()
        let cleanup = SessionCleanup(steps: makeSteps(counter))
        await cleanup.observe(.signedIn)
        let failed = await cleanup.observe(.signedOut)
        #expect(failed.isEmpty)
        #expect(await counter.order == ["saved", "context", "consent", "images", "uploads", "push"])
    }

    @Test func doesNotActOnStartupWhenThereWasNoSession() async {
        let counter = Counter()
        let cleanup = SessionCleanup(steps: makeSteps(counter))
        await cleanup.observe(.unknown)
        await cleanup.observe(.signedOut)
        #expect(await counter.order.isEmpty)
    }

    @Test func aFailingStepDoesNotStopTheOthers() async {
        let counter = Counter()
        let cleanup = SessionCleanup(steps: makeSteps(counter, failing: "consent"))
        await cleanup.observe(.signedIn)
        let failed = await cleanup.observe(.signedOut)
        #expect(failed == ["consent"])
        #expect(await counter.order.count == 6)
    }

    @Test func anExpiredSessionCleansLikeAManualSignOutAndOnlyOnce() async {
        let counter = Counter()
        let cleanup = SessionCleanup(steps: makeSteps(counter), initialStatus: .unknown)
        await cleanup.observe(.signedIn)
        await cleanup.observe(.signedOut)
        await cleanup.observe(.signedOut)
        #expect(await counter.order.count == 6)
    }

    @Test func watchObservesTheIdentityStream() async {
        let counter = Counter()
        let cleanup = SessionCleanup(steps: makeSteps(counter))
        let (stream, continuation) = AsyncStream.makeStream(of: IdentityState.self)
        let task = Task { await cleanup.watch(stream) }
        continuation.yield(IdentityState(status: .signedIn))
        continuation.yield(IdentityState(status: .signedOut, error: .sessionExpired))
        #expect(await eventually { await counter.order.count == 6 })
        continuation.finish()
        await task.value
    }
}

struct OnboardingStoreTests {
    @Test func welcomeIsShownOnceAndResetBringsItBack() async {
        let store = InMemoryOnboardingStore()
        #expect(await store.welcomeSeen() == false)
        await store.setWelcomeSeen()
        #expect(await store.welcomeSeen())
        await store.reset()
        #expect(await store.welcomeSeen() == false)
    }
}
