import CoreConsent
import CoreContext
import Foundation

/// Preferencias NO sensibles en `UserDefaults` (ADR-IOS-0006). Los tokens nunca van aquí: solo en el Keychain.
/// `UserDefaults` es seguro entre hilos, por eso `@unchecked Sendable`.
public final class UserDefaultsConsentStore: ConsentStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "consent.analytics.granted"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func read() async -> Bool { defaults.bool(forKey: key) }

    public func write(_ granted: Bool) async {
        defaults.set(granted, forKey: key)
    }
}

public final class UserDefaultsContextPreferences: ContextPreferences, @unchecked Sendable {
    private let defaults: UserDefaults
    private let lastKey = "context.last"
    private let seenKey = "context.seen"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func lastContext() async -> String? { defaults.string(forKey: lastKey) }

    public func setLastContext(_ value: String) async {
        defaults.set(value, forKey: lastKey)
    }

    public func seenContexts() async -> Set<String> {
        Set(defaults.stringArray(forKey: seenKey) ?? [])
    }

    public func markSeen(_ values: Set<String>) async {
        let merged = Set(defaults.stringArray(forKey: seenKey) ?? []).union(values)
        defaults.set(Array(merged).sorted(), forKey: seenKey)
    }

    public func clearContextState() async {
        defaults.removeObject(forKey: lastKey)
        defaults.removeObject(forKey: seenKey)
    }
}

public final class UserDefaultsOnboardingStore: OnboardingStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "onboarding.welcome.seen"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func welcomeSeen() async -> Bool { defaults.bool(forKey: key) }

    public func setWelcomeSeen() async {
        defaults.set(true, forKey: key)
    }

    public func reset() async {
        defaults.removeObject(forKey: key)
    }
}
