import Foundation

/// Contextos de la app (ADR-IOS-0022): cliente (invitado), propietario y administración. Cambiar de contexto no
/// toca la sesión ni los tokens: solo cambia qué parte de la app se enseña.
public enum UserContext: String, CaseIterable, Sendable, Codable {
    case guest
    case owner
    case admin
}

public struct ContextState: Sendable, Equatable {
    public var available: [UserContext]
    public var active: UserContext
    /// Hay un contexto que el usuario aún no sabe que tiene: se enseña el aviso de la primera vez.
    public var hintPending: Bool

    public init(available: [UserContext] = [.guest], active: UserContext = .guest, hintPending: Bool = false) {
        self.available = available
        self.active = active
        self.hintPending = hintPending
    }

    public var canSwitch: Bool { available.count > 1 }

    /// El último usado, si sigue permitido; si no (revocado o sin sesión), el de cliente. El aviso sale una vez
    /// por cada contexto nuevo (distinto del de cliente) que la persona aún no ha visto.
    public static func make(available: Set<UserContext>, last: String?, seen: Set<String>) -> ContextState {
        let ordered = UserContext.allCases.filter { available.contains($0) }
        let active = ordered.first { $0.rawValue == last } ?? .guest
        let pending = ordered.contains { $0 != .guest && !seen.contains($0.rawValue) }
        return ContextState(available: ordered, active: active, hintPending: pending)
    }
}
