import Foundation

/// Preferencias del contexto, en el dispositivo (UserDefaults, ADR-IOS-0006). Se guardan por nombre.
public protocol ContextPreferences: Sendable {
    func lastContext() async -> String?
    func setLastContext(_ value: String) async
    func seenContexts() async -> Set<String>
    func markSeen(_ values: Set<String>) async
    /// Al cerrar sesión: el último contexto y los avisos vistos son de la persona, no del dispositivo.
    func clearContextState() async
}

/// Contexto activo y aviso de primera vez (decisiones de Andy, 2026-10-15). Las capacidades (qué contextos tiene la
/// persona) las da el servidor; aquí solo se guarda lo que la persona eligió y vio.
public actor ContextManager {
    private let preferences: ContextPreferences

    public init(preferences: ContextPreferences) {
        self.preferences = preferences
    }

    public func state(available: Set<UserContext>) async -> ContextState {
        ContextState.make(
            available: available,
            last: await preferences.lastContext(),
            seen: await preferences.seenContexts()
        )
    }

    /// Solo se puede elegir un contexto que la persona tiene: ocultar la interfaz no autoriza nada (ADR-IOS-0022).
    public func select(_ context: UserContext, available: Set<UserContext>) async {
        guard available.contains(context) else { return }
        await preferences.setLastContext(context.rawValue)
    }

    /// Abrir la hoja de contextos o cerrar el globo cuenta como enterado de todos los contextos actuales.
    public func acknowledgeHint(available: Set<UserContext>) async {
        await preferences.markSeen(Set(available.map(\.rawValue)))
    }

    public func reset() async {
        await preferences.clearContextState()
    }
}
