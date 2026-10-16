#if canImport(DeviceCheck) && canImport(CryptoKit)
    import CoreAttest
    import CryptoKit
    import DeviceCheck
    import Foundation

    /// SHA-256 con CryptoKit para el hash de la petición.
    public struct CryptoKitHasher: RequestHasher {
        public init() {}

        public func sha256(_ data: Data) -> Data {
            Data(SHA256.hash(data: data))
        }
    }

    /// App Attest (ADR-IOS-0008). La clave se genera por instalación; la aserción lleva el hash de la petición. Si el
    /// dispositivo no lo soporta (por ejemplo el simulador) `isSupported` es falso y la cabecera se omite.
    /// LIMITACIÓN del PoC, sin verificar: aquí NO se hace la ATESTACIÓN contra el servidor (necesita un desafío del
    /// backend, que no existe); una aserción sin clave atestiguada la rechazaría un servidor real.
    /// Demuestra la política local (omitir si no se soporta, qué se firma), no la integración completa.
    /// Requiere iPhone real (nivel C).
    public final class AppAttestService: AttestationService, @unchecked Sendable {
        private let service = DCAppAttestService.shared
        private let defaults: UserDefaults
        private let keyIDKey = "attest.keyid"

        public init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
        }

        public var isSupported: Bool { service.isSupported }

        public func assertion(clientDataHash: Data) async throws -> Data {
            let keyID = try await currentKeyID()
            return try await service.generateAssertion(keyID, clientDataHash: clientDataHash)
        }

        private func currentKeyID() async throws -> String {
            if let stored = defaults.string(forKey: keyIDKey) { return stored }
            let created = try await service.generateKey()
            defaults.set(created, forKey: keyIDKey)
            return created
        }
    }
#endif
