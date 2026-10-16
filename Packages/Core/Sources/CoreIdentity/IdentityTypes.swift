import Foundation

public enum IdentityStatus: Sendable, Equatable {
    case unknown
    case signedOut
    case signedIn
}

/// Errores que la interfaz sabe explicar. Sin texto libre del servidor: puede llevar datos del usuario.
public enum IdentityError: Error, Sendable, Equatable {
    case notConfigured
    case canceled
    case sessionExpired
    case network
    case failed
}

/// Estado público de la sesión. Nunca lleva tokens, solo cuándo caduca el de acceso.
public struct IdentityState: Sendable, Equatable {
    public var status: IdentityStatus
    public var error: IdentityError?
    public var expiresAt: Date?

    public init(status: IdentityStatus = .unknown, error: IdentityError? = nil, expiresAt: Date? = nil) {
        self.status = status
        self.error = error
        self.expiresAt = expiresAt
    }
}

public struct Tokens: Sendable, Equatable, Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let idToken: String?
    public let expiresAt: Date?

    public init(accessToken: String, refreshToken: String?, idToken: String?, expiresAt: Date?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.expiresAt = expiresAt
    }
}

/// Almacén de tokens. En la app real es el Keychain, accesible tras el primer desbloqueo y sin iCloud
/// (ADR-IOS-0007). Los tokens no se guardan en ningún otro sitio.
public protocol TokenStore: Sendable {
    func read() async throws -> Tokens?
    func write(_ tokens: Tokens) async throws
    func clear() async
}

/// Lo que la lógica de sesión necesita del servidor de identidad (AppAuth en la app real).
public protocol AuthBackend: Sendable {
    func refresh(refreshToken: String) async throws -> Tokens
    func revoke(refreshToken: String) async throws
    func endSessionURL(idToken: String?) async throws -> URL?
}
