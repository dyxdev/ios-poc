import CoreModel
import Foundation

/// Lógica de sesión de ADR-IOS-0007: tokens solo en el almacén seguro, renovación serializada (una sola en
/// curso: las demás esperan al mismo resultado) y cierre de sesión que revoca, limpia y devuelve la URL del
/// cierre SSO. Sin BFF: la app es cliente público y renueva ella misma.
public actor IdentityManager {
    private let backend: AuthBackend
    private let store: TokenStore
    private let now: @Sendable () -> Date
    private let expirySkew: TimeInterval
    private let broadcaster = Broadcaster(IdentityState())
    private var cached: Tokens?
    private var inFlight: Task<Tokens, Error>?

    public init(
        backend: AuthBackend,
        store: TokenStore,
        now: @escaping @Sendable () -> Date = { Date() },
        expirySkew: TimeInterval = 60
    ) {
        self.backend = backend
        self.store = store
        self.now = now
        self.expirySkew = expirySkew
    }

    public var state: IdentityState {
        get async { await broadcaster.current }
    }

    public func updates() async -> AsyncStream<IdentityState> {
        await broadcaster.updates()
    }

    /// Lee la sesión guardada al arrancar. Si el almacén no se puede leer (por ejemplo, no se descifra), no hay sesión.
    public func restore() async {
        let stored = try? await store.read()
        cached = stored
        await publish(stored.map(Self.signedIn) ?? Self.signedOut(nil))
    }

    /// El flujo de login (AppAuth) terminó bien: se guardan los tokens y la sesión pasa a «iniciada».
    public func completeSignIn(_ tokens: Tokens) async throws {
        try await store.write(tokens)
        cached = tokens
        await publish(Self.signedIn(tokens))
    }

    /// El login no terminó (el usuario cerró la pestaña o falló): se anota el error sin tocar la sesión.
    public func signInFailed(_ error: IdentityError) async {
        var current = await broadcaster.current
        current.error = error
        await broadcaster.send(current)
    }

    /// Token de acceso vigente, renovándolo si hace falta. `nil` si no hay sesión o no se pudo renovar.
    public func freshAccessToken(forceRefresh: Bool = false) async -> String? {
        guard let tokens = cached else { return nil }
        if !forceRefresh, !isExpired(tokens) {
            return tokens.accessToken
        }
        guard let refreshToken = tokens.refreshToken else {
            if isExpired(tokens) {
                await expire(.sessionExpired)
                return nil
            }
            return tokens.accessToken
        }
        do {
            return try await renew(refreshToken: refreshToken).accessToken
        } catch IdentityError.sessionExpired {
            await expire(.sessionExpired)
            return nil
        } catch {
            // Sin red (o fallo transitorio) se conserva la sesión; solo se devuelve el token si aún es válido.
            return isExpired(tokens) ? nil : tokens.accessToken
        }
    }

    /// Revoca (mejor esfuerzo), limpia lo local y devuelve la URL que cierra también la sesión SSO.
    public func signOut() async -> URL? {
        let tokens = cached
        if let refreshToken = tokens?.refreshToken {
            try? await backend.revoke(refreshToken: refreshToken)
        }
        let endSession = try? await backend.endSessionURL(idToken: tokens?.idToken)
        await store.clear()
        cached = nil
        await publish(Self.signedOut(nil))
        return endSession
    }

    private func renew(refreshToken: String) async throws -> Tokens {
        if let running = inFlight {
            return try await running.value
        }
        let backend = backend
        let task = Task { try await backend.refresh(refreshToken: refreshToken) }
        inFlight = task
        defer { inFlight = nil }
        let renewed = try await task.value
        // El servidor puede no devolver refresh ni id token: se conservan los anteriores.
        let merged = Tokens(
            accessToken: renewed.accessToken,
            refreshToken: renewed.refreshToken ?? refreshToken,
            idToken: renewed.idToken ?? cached?.idToken,
            expiresAt: renewed.expiresAt
        )
        try await store.write(merged)
        cached = merged
        await publish(Self.signedIn(merged))
        return merged
    }

    private func expire(_ error: IdentityError) async {
        await store.clear()
        cached = nil
        await publish(Self.signedOut(error))
    }

    private func isExpired(_ tokens: Tokens) -> Bool {
        guard let expiresAt = tokens.expiresAt else { return false }
        return now().addingTimeInterval(expirySkew) >= expiresAt
    }

    private func publish(_ state: IdentityState) async {
        await broadcaster.send(state)
    }

    private static func signedIn(_ tokens: Tokens) -> IdentityState {
        IdentityState(status: .signedIn, error: nil, expiresAt: tokens.expiresAt)
    }

    private static func signedOut(_ error: IdentityError?) -> IdentityState {
        IdentityState(status: .signedOut, error: error, expiresAt: nil)
    }
}
