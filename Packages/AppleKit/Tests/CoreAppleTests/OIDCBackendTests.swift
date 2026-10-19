import CoreIdentity
import Foundation
import Testing

@testable import CoreApple

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func discoveryJSON(host: String, withRevocation: Bool = true, withEndSession: Bool = true) -> Data {
    var fields = ["\"token_endpoint\": \"https://\(host)/token\""]
    if withRevocation { fields.append("\"revocation_endpoint\": \"https://\(host)/revoke\"") }
    if withEndSession { fields.append("\"end_session_endpoint\": \"https://\(host)/logout\"") }
    return Data("{\(fields.joined(separator: ","))}".utf8)
}

private func backend(host: String, routes: [String: StubURLProtocol.Stub]) -> OIDCBackend {
    var all = routes
    // El emisor es https://host/realms/test: el descubrimiento cuelga de su ruta.
    let discoveryPath = "/realms/test/.well-known/openid-configuration"
    if all[discoveryPath] == nil {
        all[discoveryPath] = .init(status: 200, body: discoveryJSON(host: host))
    }
    StubURLProtocol.registry.register(host: host, routes: all)
    let configuration = OIDCConfiguration(
        issuer: URL(string: "https://\(host)/realms/test")!,
        clientID: "venuenexa-ios",
        redirectURI: URL(string: "com.venuenexa.pocios:/oauth2redirect")!
    )
    return OIDCBackend(configuration: configuration, session: StubURLProtocol.session(), now: { t0 })
}

struct OIDCBackendTests {
    @Test func refreshReturnsTokensWithExpiryFromExpiresIn() async throws {
        let host = "idp-refresh-ok.test"
        let body = Data(
            #"{"access_token":"a2","refresh_token":"r2","id_token":"i2","expires_in":300}"#.utf8
        )
        let sut = backend(host: host, routes: ["/token": .init(status: 200, body: body)])
        let tokens = try await sut.refresh(refreshToken: "r1")
        #expect(tokens.accessToken == "a2")
        #expect(tokens.refreshToken == "r2")
        #expect(tokens.expiresAt == t0.addingTimeInterval(300))
    }

    @Test func refreshSendsTheFormWithoutSecretsOtherThanTheRefreshToken() async throws {
        let host = "idp-refresh-form.test"
        let sut = backend(
            host: host,
            routes: ["/token": .init(status: 200, body: Data(#"{"access_token":"a2"}"#.utf8))]
        )
        _ = try await sut.refresh(refreshToken: "r1")
        let sent = StubURLProtocol.registry.requests(host: host).first { $0.path == "/token" }
        #expect(sent?.method == "POST")
        #expect(sent?.contentType == "application/x-www-form-urlencoded")
        #expect(sent?.body == "client_id=venuenexa-ios&grant_type=refresh_token&refresh_token=r1")
    }

    @Test func invalidGrantEndsTheSession() async {
        let sut = backend(host: "idp-invalid-grant.test", routes: ["/token": .init(status: 400, body: Data())])
        await #expect(throws: IdentityError.sessionExpired) {
            _ = try await sut.refresh(refreshToken: "r1")
        }
    }

    @Test func aServerErrorIsAGenericFailureNotAnExpiredSession() async {
        let sut = backend(host: "idp-server-error.test", routes: ["/token": .init(status: 500, body: Data())])
        await #expect(throws: IdentityError.failed) {
            _ = try await sut.refresh(refreshToken: "r1")
        }
    }

    @Test func discoveryFailureIsANetworkError() async {
        let host = "idp-no-discovery.test"
        StubURLProtocol.registry.register(host: host, routes: [:])
        let configuration = OIDCConfiguration(
            issuer: URL(string: "https://\(host)/realms/test")!,
            clientID: "venuenexa-ios",
            redirectURI: URL(string: "com.venuenexa.pocios:/oauth2redirect")!
        )
        let sut = OIDCBackend(configuration: configuration, session: StubURLProtocol.session())
        await #expect(throws: IdentityError.network) {
            _ = try await sut.refresh(refreshToken: "r1")
        }
    }

    @Test func revokeSendsTheTokenAndTheClient() async throws {
        let host = "idp-revoke.test"
        let sut = backend(host: host, routes: ["/revoke": .init(status: 200, body: Data())])
        try await sut.revoke(refreshToken: "r1")
        let sent = StubURLProtocol.registry.requests(host: host).first { $0.path == "/revoke" }
        #expect(sent?.body == "client_id=venuenexa-ios&token=r1&token_type_hint=refresh_token")
    }

    @Test func endSessionURLCarriesTheClientTheRedirectAndTheIdTokenHint() async throws {
        let sut = backend(host: "idp-endsession.test", routes: [:])
        let url = try #require(try await sut.endSessionURL(idToken: "id-1"))
        let items = Dictionary(
            uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
                .map { ($0.name, $0.value ?? "") }
        )
        #expect(url.path == "/logout")
        #expect(items["client_id"] == "venuenexa-ios")
        #expect(items["post_logout_redirect_uri"] == "com.venuenexa.pocios:/oauth2redirect")
        #expect(items["id_token_hint"] == "id-1")
    }

    @Test func endSessionURLOmitsTheHintWithoutAnIdToken() async throws {
        let sut = backend(host: "idp-endsession-nohint.test", routes: [:])
        let url = try #require(try await sut.endSessionURL(idToken: nil))
        #expect(!url.absoluteString.contains("id_token_hint"))
    }
}
