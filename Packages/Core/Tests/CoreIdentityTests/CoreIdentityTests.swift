import CoreTesting
import Foundation
import Testing

@testable import CoreIdentity

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func tokens(
    access: String = "access-1",
    refresh: String? = "refresh-1",
    id: String? = "id-1",
    expiresIn seconds: TimeInterval = 3600
) -> Tokens {
    Tokens(accessToken: access, refreshToken: refresh, idToken: id, expiresAt: t0.addingTimeInterval(seconds))
}

private func manager(
    store: InMemoryTokenStore,
    backend: FakeAuthBackend,
    now: @escaping @Sendable () -> Date = { t0 }
) -> IdentityManager {
    IdentityManager(backend: backend, store: store, now: now)
}

struct IdentityManagerTests {
    @Test func restoreWithoutTokensMeansSignedOut() async {
        let sut = manager(store: InMemoryTokenStore(), backend: FakeAuthBackend(refreshResult: .success(tokens())))
        await sut.restore()
        #expect(await sut.state.status == .signedOut)
    }

    @Test func restoreWithTokensMeansSignedInAndExposesOnlyTheExpiry() async {
        let stored = tokens()
        let sut = manager(
            store: InMemoryTokenStore(stored),
            backend: FakeAuthBackend(refreshResult: .success(tokens()))
        )
        await sut.restore()
        let state = await sut.state
        #expect(state.status == .signedIn)
        #expect(state.expiresAt == stored.expiresAt)
    }

    @Test func aValidTokenIsReturnedWithoutRenewing() async {
        let backend = FakeAuthBackend(refreshResult: .success(tokens(access: "new")))
        let sut = manager(store: InMemoryTokenStore(tokens()), backend: backend)
        await sut.restore()
        #expect(await sut.freshAccessToken() == "access-1")
        #expect(await backend.refreshCalls == 0)
    }

    @Test func fiveConcurrentCallsShareASingleRenewal() async {
        let backend = FakeAuthBackend(
            refreshResult: .success(tokens(access: "access-2", refresh: "refresh-2")),
            delay: .milliseconds(120)
        )
        let store = InMemoryTokenStore(tokens())
        let sut = manager(store: store, backend: backend)
        await sut.restore()
        let results = await withTaskGroup(of: String?.self) { group in
            for _ in 0..<5 {
                group.addTask { await sut.freshAccessToken(forceRefresh: true) }
            }
            var all: [String?] = []
            for await result in group { all.append(result) }
            return all
        }
        #expect(await backend.refreshCalls == 1)
        #expect(results.allSatisfy { $0 == "access-2" })
        #expect(await store.stored?.refreshToken == "refresh-2")
    }

    @Test func anExpiredTokenIsRenewedAndKeepsTheOldRefreshAndIDTokensIfNoneComeBack() async {
        let renewed = Tokens(
            accessToken: "access-2",
            refreshToken: nil,
            idToken: nil,
            expiresAt: t0.addingTimeInterval(7200)
        )
        let backend = FakeAuthBackend(refreshResult: .success(renewed))
        let store = InMemoryTokenStore(tokens(expiresIn: 30))
        let sut = manager(store: store, backend: backend)
        await sut.restore()
        #expect(await sut.freshAccessToken() == "access-2")
        #expect(await store.stored?.refreshToken == "refresh-1")
        #expect(await store.stored?.idToken == "id-1")
    }

    @Test func aRejectedRefreshTokenEndsTheSessionAndClearsTheStore() async {
        let backend = FakeAuthBackend(refreshResult: .failure(.sessionExpired))
        let store = InMemoryTokenStore(tokens(expiresIn: 30))
        let sut = manager(store: store, backend: backend)
        await sut.restore()
        #expect(await sut.freshAccessToken() == nil)
        let state = await sut.state
        #expect(state.status == .signedOut)
        #expect(state.error == .sessionExpired)
        #expect(await store.stored == nil)
    }

    @Test func noNetworkKeepsTheSessionAndStillServesAStillValidToken() async {
        let backend = FakeAuthBackend(refreshResult: .failure(.network))
        let sut = manager(store: InMemoryTokenStore(tokens(expiresIn: 3600)), backend: backend)
        await sut.restore()
        #expect(await sut.freshAccessToken(forceRefresh: true) == "access-1")
        #expect(await sut.state.status == .signedIn)
    }

    @Test func noNetworkWithAnExpiredTokenReturnsNilButKeepsTheSession() async {
        let backend = FakeAuthBackend(refreshResult: .failure(.network))
        let sut = manager(store: InMemoryTokenStore(tokens(expiresIn: 10)), backend: backend)
        await sut.restore()
        #expect(await sut.freshAccessToken() == nil)
        #expect(await sut.state.status == .signedIn)
    }

    @Test func signOutRevokesClearsAndReturnsTheSSOLogoutURL() async throws {
        let logout = try #require(URL(string: "https://idp.example/logout"))
        let backend = FakeAuthBackend(refreshResult: .success(tokens()), endSession: logout)
        let store = InMemoryTokenStore(tokens())
        let sut = manager(store: store, backend: backend)
        await sut.restore()
        let url = await sut.signOut()
        #expect(url == logout)
        #expect(await backend.revokedTokens == ["refresh-1"])
        #expect(await store.stored == nil)
        #expect(await sut.state.status == .signedOut)
        #expect(await sut.freshAccessToken() == nil)
    }

    @Test func completeSignInStoresTheTokensAndSignsIn() async throws {
        let store = InMemoryTokenStore()
        let sut = manager(store: store, backend: FakeAuthBackend(refreshResult: .success(tokens())))
        await sut.restore()
        try await sut.completeSignIn(tokens(access: "fresh"))
        #expect(await sut.state.status == .signedIn)
        #expect(await store.stored?.accessToken == "fresh")
    }

    @Test func aFailedSignInOnlyRecordsTheError() async {
        let sut = manager(store: InMemoryTokenStore(), backend: FakeAuthBackend(refreshResult: .success(tokens())))
        await sut.restore()
        await sut.signInFailed(.canceled)
        let state = await sut.state
        #expect(state.status == .signedOut)
        #expect(state.error == .canceled)
    }
}
