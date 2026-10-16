import Foundation

/// Operaciones que llevan aserción de App Attest (ADR-IOS-0008).
public enum AttestedOperation: String, CaseIterable, Sendable {
    case firstCallAfterLogin
    case deviceRegistration
    case pushRegistration
    case booking
    case payment
    case payout
    case roleChange
    case refund
    case sanction
    /// Cualquier otra llamada: no lleva aserción.
    case other
}

public protocol RequestHasher: Sendable {
    func sha256(_ data: Data) -> Data
}

public protocol AttestationService: Sendable {
    var isSupported: Bool { get }
    func assertion(clientDataHash: Data) async throws -> Data
}

/// Construye la cabecera de App Attest. Si el dispositivo no lo soporta (`isSupported` falso, por ejemplo el
/// simulador) la aserción se omite: el servidor no puede exigirla. La aserción lleva el hash de la petición
/// (método, ruta y cuerpo) para que no sirva en otra. Sin certificate pinning (ADR-IOS-0008).
public struct AttestedRequestSigner: Sendable {
    public static let headerName = "X-App-Attest-Assertion"

    private let service: AttestationService
    private let hasher: RequestHasher

    public init(service: AttestationService, hasher: RequestHasher) {
        self.service = service
        self.hasher = hasher
    }

    public static func requiresAttestation(_ operation: AttestedOperation) -> Bool {
        operation != .other
    }

    public func headers(
        operation: AttestedOperation,
        method: String,
        path: String,
        body: Data
    ) async throws -> [String: String] {
        guard Self.requiresAttestation(operation), service.isSupported else { return [:] }
        var material = Data("\(method.uppercased())\n\(path)\n".utf8)
        material.append(body)
        let assertion = try await service.assertion(clientDataHash: hasher.sha256(material))
        return [Self.headerName: assertion.base64EncodedString()]
    }
}
