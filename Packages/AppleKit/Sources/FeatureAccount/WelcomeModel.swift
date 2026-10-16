import CoreContext
import CoreIdentity
import CoreModel
import CoreVenues
import Foundation
import Observation

/// Bienvenida «Explorar / Iniciar sesión» (solo la primera vez, decisión de Andy, 2026-10-15). Las portadas del collage
/// son las de los primeros venues destacados. Continúa solo si la persona pidió el login desde esta pantalla: la
/// restauración de una sesión guardada, que llega un instante después de abrir la app, no se salta la bienvenida.
@MainActor
@Observable
public final class WelcomeModel {
    public private(set) var covers: [URL]?
    public private(set) var identity = IdentityState()
    public private(set) var signInRequested = false

    private let repository: VenueRepository
    private let identityManager: IdentityManager
    private let onboarding: OnboardingStore
    private let performSignIn: @MainActor (String?) async -> Void

    public init(
        repository: VenueRepository,
        identityManager: IdentityManager,
        onboarding: OnboardingStore,
        signIn: @escaping @MainActor (String?) async -> Void
    ) {
        self.repository = repository
        self.identityManager = identityManager
        self.onboarding = onboarding
        performSignIn = signIn
    }

    public var showsSignIn: Bool { identity.status != .signedIn }

    public func loadCovers() async {
        let venues = await repository.venues()
        covers = venues.filter(\.isFeatured).prefix(3).map(\.cover)
    }

    public func observeIdentity() async {
        for await state in await identityManager.updates() {
            identity = state
        }
    }

    public func requestSignIn() {
        signInRequested = true
        Task { await performSignIn(nil) }
    }

    /// ¿Debe cerrarse la bienvenida porque la sesión se inició desde aquí?
    public var shouldFinishAfterSignIn: Bool { signInRequested && identity.status == .signedIn }

    /// Al volver a mostrar la bienvenida (diagnóstico) no queda memoria de un login pedido antes.
    public func prepareToShow() {
        signInRequested = false
    }

    public func markSeen() async {
        await onboarding.setWelcomeSeen()
    }
}
