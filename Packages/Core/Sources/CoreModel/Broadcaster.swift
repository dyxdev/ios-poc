import Foundation

/// Un valor observable: guarda el último y reparte los cambios a quien lo escuche. Sustituye a `StateFlow`
/// sin singletons ni callbacks (ADR-IOS-0002 y 0005): `AsyncStream` y un actor.
public actor Broadcaster<Value: Sendable> {
    private var value: Value
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    public init(_ initial: Value) {
        value = initial
    }

    public var current: Value { value }

    public func send(_ newValue: Value) {
        value = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }

    /// Un flujo que entrega primero el valor actual y después cada cambio.
    public func updates() -> AsyncStream<Value> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self)
        continuations[id] = continuation
        continuation.yield(value)
        continuation.onTermination = { [weak self] _ in
            Task { await self?.remove(id) }
        }
        return stream
    }

    private func remove(_ id: UUID) {
        continuations[id] = nil
    }
}
