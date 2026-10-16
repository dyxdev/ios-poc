import CoreModel
import Foundation

public enum RetryDecision: Equatable, Sendable {
    case doNotRetry
    case retry(after: TimeInterval)
}

/// Reintentos de ADR-IOS-0013: solo se reintentan las lecturas; una mutación solo si lleva clave de idempotencia
/// (y se reintenta con la MISMA clave). `rateLimited` espera el `Retry-After`; `conflict` no se reintenta.
public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval

    public init(maxAttempts: Int = 3, baseDelay: TimeInterval = 0.5) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
    }

    public func decision(
        for error: AppError,
        attempt: Int,
        isRead: Bool,
        hasIdempotencyKey: Bool
    ) -> RetryDecision {
        guard attempt < maxAttempts, isRead || hasIdempotencyKey else { return .doNotRetry }
        switch error {
        case let .rateLimited(retryAfter, _):
            return .retry(after: retryAfter ?? backoff(attempt))
        case .unavailable:
            return .retry(after: backoff(attempt))
        default:
            // validation, unauthorized, stepUp, forbidden, notFound, conflict, updateRequired, unexpected.
            return .doNotRetry
        }
    }

    private func backoff(_ attempt: Int) -> TimeInterval {
        baseDelay * pow(2, Double(attempt))
    }
}
