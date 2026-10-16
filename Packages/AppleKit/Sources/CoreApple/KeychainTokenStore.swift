import CoreIdentity
import Foundation
import Security

/// Tokens SOLO en el Keychain (ADR-IOS-0007): accesibles tras el primer desbloqueo, solo en este dispositivo (sin
/// iCloud ni copia). Es lo único que guarda tokens; ni `UserDefaults` ni el disco.
public struct KeychainTokenStore: TokenStore {
    public enum StoreError: Error, Equatable, Sendable {
        case unexpectedStatus(Int32)
    }

    private let service: String
    private let account = "session"

    public init(service: String = "com.venuenexa.pocios.tokens") {
        self.service = service
    }

    public func read() async throws -> Tokens? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            return try JSONDecoder().decode(Tokens.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unexpectedStatus(status)
        }
    }

    public func write(_ tokens: Tokens) async throws {
        let data = try JSONEncoder().encode(tokens)
        SecItemDelete(baseQuery() as CFDictionary)
        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw StoreError.unexpectedStatus(status) }
    }

    public func clear() async {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
        ]
    }
}

/// Los items del Keychain suelen sobrevivir a una reinstalación y ningún ADR lo trata (hueco 14 del plan). Decisión del
/// agente, REVERSIBLE y pendiente de confirmar con Andy: en el primer arranque tras instalar se borran.
public enum FreshInstallGuard {
    public static func clearKeychainIfFreshInstall(
        store: KeychainTokenStore,
        defaults: UserDefaults = .standard
    ) async {
        let key = "install.marker"
        guard !defaults.bool(forKey: key) else { return }
        await store.clear()
        defaults.set(true, forKey: key)
    }
}
