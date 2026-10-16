import CoreConsent
import CoreContext
import CoreIdentity
import Foundation
import Observation

/// Sesión y privacidad de la cuenta. Sin tokens ni datos personales en el estado. El login (AppAuth, navegador del
/// sistema) y el cierre de sesión llegan como cierres desde la app: esta feature no conoce a AppAuth ni al Keychain.
@MainActor
@Observable
public final class AccountModel {
    public private(set) var identity = IdentityState()
    public private(set) var analyticsConsent = false

    private let identityManager: IdentityManager
    private let consent: ConsentGate
    private let performSignIn: @MainActor (String?) async -> Void
    private let performSignOut: @MainActor () async -> Void

    public init(
        identityManager: IdentityManager,
        consent: ConsentGate,
        signIn: @escaping @MainActor (String?) async -> Void,
        signOut: @escaping @MainActor () async -> Void
    ) {
        self.identityManager = identityManager
        self.consent = consent
        performSignIn = signIn
        performSignOut = signOut
    }

    public var isSignedIn: Bool { identity.status == .signedIn }

    public func observeIdentity() async {
        for await state in await identityManager.updates() {
            identity = state
        }
    }

    public func observeConsent() async {
        for await granted in await consent.updates() {
            analyticsConsent = granted
        }
    }

    /// `idpHint = "google"` lleva directo al proveedor de Google por el brokering de Keycloak (`kc_idp_hint`).
    public func signIn(idpHint: String? = nil) {
        Task { await performSignIn(idpHint) }
    }

    public func signOut() {
        Task { await performSignOut() }
    }

    public func setAnalyticsConsent(_ granted: Bool) {
        Task { await consent.setGranted(granted) }
    }

    /// Texto de «Acceso válido hasta las HH:mm» (es la caducidad del token de acceso, que se renueva solo).
    public func expiryText(locale: Locale) -> String? {
        guard let expiresAt = identity.expiresAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: expiresAt)
    }
}

extension IdentityError {
    public var messageKey: String {
        switch self {
        case .notConfigured: "account.error.notconfigured"
        case .canceled: "account.error.canceled"
        case .sessionExpired: "account.error.expired"
        case .network: "account.error.network"
        case .failed: "account.error.failed"
        }
    }
}
