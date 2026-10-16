import Foundation

public enum UnavailableReason: Sendable, Equatable {
    case offline
    case server
}

/// Errores de la aplicación (ADR-IOS-0013): casos fijos, convertidos una sola vez en la capa de datos.
/// Las vistas nunca interpretan HTTP: muestran el texto del caso y el código de soporte (`correlationID`).
public enum AppError: Error, Equatable, Sendable {
    case validation(correlationID: String?)
    case unauthorized(correlationID: String?)
    case stepUpRequired(correlationID: String?)
    case forbidden(correlationID: String?)
    case notFound(correlationID: String?)
    case conflict(correlationID: String?)
    case rateLimited(retryAfter: TimeInterval?, correlationID: String?)
    case unavailable(reason: UnavailableReason, correlationID: String?)
    case updateRequired(correlationID: String?)
    case unexpected(correlationID: String?)

    public var correlationID: String? {
        switch self {
        case let .validation(id), let .unauthorized(id), let .stepUpRequired(id), let .forbidden(id),
             let .notFound(id), let .conflict(id), let .updateRequired(id), let .unexpected(id):
            return id
        case let .rateLimited(_, id), let .unavailable(_, id):
            return id
        }
    }

    /// Convierte una respuesta de la API (Problem Details) en un caso fijo. `code` es el código de negocio
    /// del cuerpo (por ejemplo `step-up-required` o `update-required`). Un código desconocido nunca rompe.
    public static func from(
        status: Int,
        code: String?,
        retryAfter: TimeInterval? = nil,
        correlationID: String? = nil
    ) -> AppError {
        switch (status, code) {
        case (_, "update-required"?), (426, _):
            return .updateRequired(correlationID: correlationID)
        case (403, "step-up-required"?):
            return .stepUpRequired(correlationID: correlationID)
        case (400, _), (422, _):
            return .validation(correlationID: correlationID)
        case (401, _):
            return .unauthorized(correlationID: correlationID)
        case (403, _):
            return .forbidden(correlationID: correlationID)
        case (404, _):
            return .notFound(correlationID: correlationID)
        case (409, _):
            return .conflict(correlationID: correlationID)
        case (429, _):
            return .rateLimited(retryAfter: retryAfter, correlationID: correlationID)
        case (502, _), (503, _), (504, _):
            return .unavailable(reason: .server, correlationID: correlationID)
        default:
            return .unexpected(correlationID: correlationID)
        }
    }
}
