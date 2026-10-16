import Foundation

/// Preferencias de primer uso, del DISPOSITIVO (no de la persona): si ya se vio la bienvenida
/// «Explorar / Iniciar sesión».
/// Sobrevive al cierre de sesión (ADR-AND-0034 y paridad iOS: «bienvenida vista» es del dispositivo).
public protocol OnboardingStore: Sendable {
    func welcomeSeen() async -> Bool
    func setWelcomeSeen() async
    /// Herramienta de diagnóstico: deja la app como recién instalada.
    func reset() async
}
