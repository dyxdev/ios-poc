import Foundation

/// La conexión real (`URLSession.bytes` en la app, ADR-IOS-0028). Un protocolo para probar con un servidor falso.
public protocol SSETransport: Sendable {
    func connect(lastEventID: String?) async throws -> AsyncThrowingStream<UInt8, Error>
}

/// Cliente SSE con reconexión: al cortarse la conexión vuelve a conectar enviando `Last-Event-ID`, para no perder
/// ni repetir eventos. Solo debe vivir en primer plano: quien lo use cancela la tarea al pasar a segundo plano.
public struct SSEClient: Sendable {
    private let transport: SSETransport
    private let maxRetries: Int
    private let backoff: @Sendable (Int) -> Duration
    private let sleep: @Sendable (Duration) async throws -> Void

    public init(
        transport: SSETransport,
        maxRetries: Int = 5,
        backoff: @escaping @Sendable (Int) -> Duration = { .seconds(min(30, 1 << min($0, 5))) },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.transport = transport
        self.maxRetries = maxRetries
        self.backoff = backoff
        self.sleep = sleep
    }

    public func events() -> AsyncThrowingStream<SSEEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: SSEEvent.self)
        let transport = transport
        let maxRetries = maxRetries
        let backoff = backoff
        let sleep = sleep
        let task = Task {
            var parser = SSEParser()
            var decoder = SSELineDecoder()
            var failures = 0
            while !Task.isCancelled {
                do {
                    let bytes = try await transport.connect(lastEventID: parser.lastEventID)
                    for try await byte in bytes {
                        failures = 0
                        guard let line = decoder.feed(byte) else { continue }
                        if let event = parser.feed(line: line) {
                            continuation.yield(event)
                        }
                    }
                } catch is CancellationError {
                    break
                } catch {
                    failures += 1
                    if failures > maxRetries {
                        continuation.finish(throwing: error)
                        return
                    }
                }
                do {
                    try await sleep(backoff(failures))
                } catch {
                    break
                }
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }
}
