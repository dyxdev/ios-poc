import CoreContext
import Foundation
import Observation

/// Estado del cambio de contexto para las pantallas: qué contextos tiene la persona, cuál está activo y si falta el
/// aviso de primera vez. Las capacidades vienen de `CapabilitiesSource` (simuladas en debug; el endpoint real aún no
/// existe) y lo elegido y visto lo guarda `ContextManager`. Cambiar de contexto NO toca la sesión (RF-002).
@MainActor
@Observable
public final class ContextSwitcherModel {
    public private(set) var state = ContextState()
    public var isSheetPresented = false

    private let manager: ContextManager
    private let capabilities: CapabilitiesSource
    private var signedIn = false
    private var available: Set<UserContext> = [.guest]

    public init(manager: ContextManager, capabilities: CapabilitiesSource) {
        self.manager = manager
        self.capabilities = capabilities
    }

    public func update(signedIn: Bool) async {
        self.signedIn = signedIn
        await refresh()
    }

    public func refresh() async {
        available = await capabilities.available(signedIn: signedIn)
        state = await manager.state(available: available)
    }

    /// Abrir la hoja cuenta como enterado de los contextos actuales (se apaga el aviso de primera vez).
    public func openSheet() {
        isSheetPresented = true
        Task { await acknowledgeHint() }
    }

    public func acknowledgeHint() async {
        await manager.acknowledgeHint(available: available)
        await refresh()
    }

    public func select(_ context: UserContext) {
        Task {
            await manager.select(context, available: available)
            await refresh()
            isSheetPresented = false
        }
    }

    /// Cierre de sesión: se olvida el contexto recordado y los avisos vistos (también lo hace `SessionCleanup`).
    public func resetAfterSignOut() async {
        await manager.reset()
        await refresh()
    }
}

extension UserContext {
    public var titleKey: String { "context.\(rawValue).title" }
    public var descriptionKey: String { "context.\(rawValue).description" }
}
