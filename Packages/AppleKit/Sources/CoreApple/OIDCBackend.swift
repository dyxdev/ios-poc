import CoreIdentity
import Foundation

/// Configuración del cliente público de Keycloak para iOS (cliente `venuenexa-ios`, PKCE S256, ADR-IOS-0007).
public struct OIDCConfiguration: Sendable, Equatable {
    public let issuer: URL
    public let clientID: String
    public let redirectURI: URL
    public let scopes: [String]

    public init(issuer: URL, clientID: String, redirectURI: URL, scopes: [String] = ["openid", "email", "profile"]) {
        self.issuer = issuer
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
}

/// Documento de descubrimiento OIDC (`/.well-known/openid-configuration`).
struct OIDCDiscovery: Decodable, Sendable {
    let tokenEndpoint: URL
    let revocationEndpoint: URL?
    let endSessionEndpoint: URL?

    enum CodingKeys: String, CodingKey {
        case tokenEndpoint = "token_endpoint"
        case revocationEndpoint = "revocation_endpoint"
        case endSessionEndpoint = "end_session_endpoint"
    }

    static func fetch(issuer: URL, session: URLSession) async throws -> OIDCDiscovery {
        let url = issuer.appendingPathComponent(".well-known/openid-configuration")
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw IdentityError.network }
        return try JSONDecoder().decode(OIDCDiscovery.self, from: data)
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let expiresIn: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
    }
}

/// Renovación, revocación y cierre SSO contra Keycloak. El login interactivo es de AppAuth (`AppAuthSignIn`).
/// Sin tokens en logs (ADR-IOS-0004): solo se registra la clase del error.
public struct OIDCBackend: AuthBackend {
    private let configuration: OIDCConfiguration
    private let session: URLSession
    private let now: @Sendable () -> Date

    public init(
        configuration: OIDCConfiguration,
        session: URLSession = URLSession(configuration: .ephemeral),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.configuration = configuration
        self.session = session
        self.now = now
    }

    public func refresh(refreshToken: String) async throws -> Tokens {
        let discovery = try await OIDCDiscovery.fetch(issuer: configuration.issuer, session: session)
        let request = Self.formRequest(
            url: discovery.tokenEndpoint,
            fields: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken,
                "client_id": configuration.clientID,
            ]
        )
        let (data, response) = try await send(request)
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
            let expiry = decoded.expiresIn.map { now().addingTimeInterval($0) }
            return Tokens(
                accessToken: decoded.accessToken,
                refreshToken: decoded.refreshToken,
                idToken: decoded.idToken,
                expiresAt: expiry
            )
        case 400, 401:
            // `invalid_grant`: el refresh token ya no vale (caducó o se revocó): la sesión termina.
            throw IdentityError.sessionExpired
        default:
            throw IdentityError.failed
        }
    }

    public func revoke(refreshToken: String) async throws {
        let discovery = try await OIDCDiscovery.fetch(issuer: configuration.issuer, session: session)
        guard let endpoint = discovery.revocationEndpoint else { return }
        let request = Self.formRequest(
            url: endpoint,
            fields: [
                "token": refreshToken,
                "token_type_hint": "refresh_token",
                "client_id": configuration.clientID,
            ]
        )
        _ = try await send(request)
    }

    /// URL que cierra también la sesión SSO de Keycloak (la app la abre en `ASWebAuthenticationSession`).
    public func endSessionURL(idToken: String?) async throws -> URL? {
        let discovery = try await OIDCDiscovery.fetch(issuer: configuration.issuer, session: session)
        guard let endpoint = discovery.endSessionEndpoint,
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        else { return nil }
        var items = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "post_logout_redirect_uri", value: configuration.redirectURI.absoluteString),
        ]
        if let idToken {
            items.append(URLQueryItem(name: "id_token_hint", value: idToken))
        }
        components.queryItems = (components.queryItems ?? []) + items
        return components.url
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Log.identity.error("Fallo de red hablando con el servidor de identidad")
            throw IdentityError.network
        }
    }

    private static func formRequest(url: URL, fields: [String: String]) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = fields.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = Data((components.percentEncodedQuery ?? "").utf8)
        return request
    }
}
