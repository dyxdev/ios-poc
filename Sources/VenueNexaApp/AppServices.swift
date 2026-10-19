import ContextUI
import CoreApple
import CoreConsent
import CoreContext
import CoreIdentity
import CoreVenues
import FeatureAccount
import FeatureHome
import FeatureOwner
import Foundation
import Observation

/// Avisos de la app hacia la raíz (hoy, uno: el diagnóstico pidió volver a mostrar la bienvenida).
@MainActor
@Observable
final class AppSignals {
    var welcomeResets = 0
}

/// Composición de la app (ADR-IOS-0002): un único sitio crea los servicios y los modelos y se los pasa a quien los
/// necesita. Sin singletons propios; los modelos reciben sus dependencias por el inicializador.
@MainActor
final class AppServices {
    let signals: AppSignals
    let repository: VenueRepository
    let saved: SavedVenues
    let consent: ConsentGate
    let identity: IdentityManager
    let onboarding: OnboardingStore
    let contextManager: ContextManager
    let switcher: ContextSwitcherModel
    let home: HomeModel
    let owner: OwnerModel
    let account: AccountModel
    let welcome: WelcomeModel
    let diagnostics: DiagnosticsModel

    private let keychain: KeychainTokenStore
    private let simulator: CapabilitySimulator?
    private let cleanup: SessionCleanup
    private let actions: SessionActions

    #if DEBUG
        static let showsDiagnostics = true
    #else
        static let showsDiagnostics = false
    #endif

    init() {
        let repository = DemoVenueRepository()
        self.repository = repository
        let consent = ConsentGate(store: UserDefaultsConsentStore())
        self.consent = consent
        let configuration = Configuration.oidc
        let keychain = KeychainTokenStore()
        self.keychain = keychain
        let identity = IdentityManager(backend: Self.backend(for: configuration), store: keychain)
        self.identity = identity
        let onboarding = UserDefaultsOnboardingStore()
        self.onboarding = onboarding
        let contextManager = ContextManager(preferences: UserDefaultsContextPreferences())
        self.contextManager = contextManager
        #if DEBUG
            let capabilities: CapabilitiesSource = SimulatedCapabilities()
        #else
            let capabilities: CapabilitiesSource = GuestOnlyCapabilities()
        #endif
        let switcher = ContextSwitcherModel(manager: contextManager, capabilities: capabilities)
        self.switcher = switcher
        let simulator = capabilities as? CapabilitySimulator
        self.simulator = simulator

        let actions = SessionActions(identity: identity, configuration: configuration)
        self.actions = actions
        let signIn: @MainActor (String?) async -> Void = { hint in await actions.signIn(idpHint: hint) }
        let signOut: @MainActor () async -> Void = { await actions.signOut() }

        let signals = AppSignals()
        self.signals = signals
        let saved = SavedVenues()
        self.saved = saved
        home = HomeModel(repository: repository, saved: saved)
        owner = OwnerModel(repository: repository)
        account = AccountModel(identityManager: identity, consent: consent, signIn: signIn, signOut: signOut)
        welcome = WelcomeModel(
            repository: repository,
            identityManager: identity,
            onboarding: onboarding,
            signIn: signIn
        )
        diagnostics = DiagnosticsModel(
            simulator: simulator,
            onboarding: onboarding,
            approvedSuffixes: Self.approvedSuffixes(configuration)
        ) {
            await switcher.refresh()
        } onWelcomeReset: {
            signals.welcomeResets += 1
        }

        cleanup = SessionCleanup(steps: [
            CleanupStep(name: "saved") { await saved.clear() },
            CleanupStep(name: "context") { await switcher.resetAfterSignOut() },
            CleanupStep(name: "consent") { await consent.setGranted(false) },
            CleanupStep(name: "images") { await ImageCaches.clearAll() },
        ])
    }

    /// Arranque: borra el Keychain tras una instalación nueva, lee el consentimiento y restaura la sesión guardada.
    func bootstrap() async {
        await FreshInstallGuard.clearKeychainIfFreshInstall(store: keychain)
        #if DEBUG
            // Capturas de CI: sesión falsa guardada DESPUÉS del borrado de instalación nueva y antes de restaurar.
            if LaunchOverrides.wantsSession {
                try? await keychain.write(LaunchOverrides.fakeTokens)
            }
        #endif
        await consent.load()
        await identity.restore()
    }

    #if DEBUG
        /// Solo capturas: concede el perfil de administración en el simulador para poder abrir esa pantalla.
        func grantAdminForScreenshots() async {
            await simulator?.setGranted(.admin, true)
        }
    #endif

    /// Limpieza al cerrar sesión por cualquier camino (ADR-IOS-0007 y paridad con ADR-AND-0034).
    func watchCleanup() async {
        for await state in await identity.updates() {
            let failedSteps = await cleanup.observe(state.status)
            if !failedSteps.isEmpty {
                let names = failedSteps.joined(separator: ",")
                Log.identity.error("Pasos de limpieza fallidos: \(names, privacy: .public)")
            }
        }
    }

    /// Mantiene las capacidades y los contextos al día con la sesión.
    func watchContext() async {
        for await state in await identity.updates() {
            await switcher.update(signedIn: state.status == .signedIn)
        }
    }

    private static func backend(for configuration: OIDCConfiguration?) -> AuthBackend {
        guard let configuration else { return UnconfiguredBackend() }
        return OIDCBackend(configuration: configuration)
    }

    private static func approvedSuffixes(_ configuration: OIDCConfiguration?) -> [String] {
        var suffixes = Configuration.approvedHostSuffixes
        if let host = configuration?.issuer.host { suffixes.append(host) }
        return suffixes
    }
}

/// Sin Keycloak configurado no hay sesión que renovar ni revocar.
private struct UnconfiguredBackend: AuthBackend {
    func refresh(refreshToken: String) async throws -> Tokens { throw IdentityError.notConfigured }
    func revoke(refreshToken: String) async throws {}
    func endSessionURL(idToken: String?) async throws -> URL? { nil }
}
