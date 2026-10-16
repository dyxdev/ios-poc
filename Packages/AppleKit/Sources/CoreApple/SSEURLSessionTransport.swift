import CoreNetwork
import Foundation

public enum SSETransportError: Error, Equatable, Sendable {
    case badStatus(Int)
    case notHTTP
}

/// Conexión SSE real sobre `URLSession.bytes` (ADR-IOS-0028: sin biblioteca de terceros). Solo en primer plano: quien
/// la usa cancela la tarea al pasar a segundo plano. `GET /v1/me/events` con el token de la app y `Last-Event-ID`.
public struct SSEURLSessionTransport: SSETransport {
    private let url: URL
    private let session: URLSession
    private let accessToken: @Sendable () async -> String?

    public init(
        url: URL,
        session: URLSession = URLSession(configuration: .default),
        accessToken: @escaping @Sendable () async -> String?
    ) {
        self.url = url
        self.session = session
        self.accessToken = accessToken
    }

    public func connect(lastEventID: String?) async throws -> AsyncThrowingStream<UInt8, Error> {
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 60
        if let lastEventID {
            request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID")
        }
        if let token = await accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw SSETransportError.notHTTP }
        guard http.statusCode == 200 else { throw SSETransportError.badStatus(http.statusCode) }
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await byte in bytes {
                        continuation.yield(byte)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
