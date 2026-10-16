import Foundation

/// Qué contextos puede usar la persona. La fuente real será el endpoint de capacidades de la API (ADR-IOS-0022),
/// que aún no existe: mientras tanto, solo hay contexto de cliente (`GuestOnlyCapabilities`) o, en las
/// configuraciones Demo y debug, la simulación.
public protocol CapabilitiesSource: Sendable {
    func available(signedIn: Bool) async -> Set<UserContext>
}

/// Producción sin endpoint: solo el contexto de cliente. Una compilación de release nunca regala contextos.
public struct GuestOnlyCapabilities: CapabilitiesSource {
    public init() {}

    public func available(signedIn: Bool) async -> Set<UserContext> {
        [.guest]
    }
}

/// Control de la simulación, solo para diagnóstico. Desaparece cuando exista el endpoint real de capacidades.
public protocol CapabilitySimulator: Sendable {
    func grantedExtras() async -> Set<UserContext>
    func setGranted(_ context: UserContext, _ isGranted: Bool) async
}

#if DEBUG
    /// Capacidades SIMULADAS (decisión de Andy, 2026-10-15): sin sesión solo hay contexto de cliente; con sesión, el
    /// de cliente más los concedidos en el simulador (por defecto, propietario). Solo existe en compilaciones de
    /// debug (ADR-IOS-0025: la configuración Demo nunca se distribuye). No salen del token: la app nunca deduce
    /// permisos de los roles del token (ADR-IOS-0022).
    public actor SimulatedCapabilities: CapabilitiesSource, CapabilitySimulator {
        private var granted: Set<UserContext> = [.owner]

        public init() {}

        public func grantedExtras() async -> Set<UserContext> { granted }

        public func setGranted(_ context: UserContext, _ isGranted: Bool) async {
            guard context != .guest else { return }
            if isGranted {
                granted.insert(context)
            } else {
                granted.remove(context)
            }
        }

        public func available(signedIn: Bool) async -> Set<UserContext> {
            signedIn ? granted.union([.guest]) : [.guest]
        }
    }
#endif
