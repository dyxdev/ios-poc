import Foundation

/// Servidor HTTP falso para las pruebas de los adaptadores de red: sin red real ni librerías de mocking (ADR-IOS-0015).
/// Cada prueba usa un host propio (`registry.register(host:)`), así las pruebas en paralelo no se pisan.
class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub {
        let status: Int
        let body: Data
    }

    final class Registry: @unchecked Sendable {
        private let lock = NSLock()
        private var stubs: [String: [String: Stub]] = [:]
        private var recorded: [String: [RecordedRequest]] = [:]

        /// Respuestas por ruta (`path`) para un host.
        func register(host: String, routes: [String: Stub]) {
            lock.lock()
            stubs[host] = routes
            recorded[host] = []
            lock.unlock()
        }

        func requests(host: String) -> [RecordedRequest] {
            lock.lock()
            defer { lock.unlock() }
            return recorded[host] ?? []
        }

        func respond(to request: URLRequest) -> Stub {
            let host = request.url?.host ?? ""
            let path = request.url?.path ?? ""
            lock.lock()
            defer { lock.unlock() }
            recorded[host, default: []].append(RecordedRequest(request))
            return stubs[host]?[path] ?? Stub(status: 404, body: Data())
        }
    }

    struct RecordedRequest: Sendable {
        let path: String
        let method: String
        let contentType: String?
        let body: String

        init(_ request: URLRequest) {
            path = request.url?.path ?? ""
            method = request.httpMethod ?? ""
            contentType = request.value(forHTTPHeaderField: "Content-Type")
            body = Self.readBody(request)
        }

        private static func readBody(_ request: URLRequest) -> String {
            if let data = request.httpBody {
                return String(data: data, encoding: .utf8) ?? ""
            }
            guard let stream = request.httpBodyStream else { return "" }
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
            return String(data: data, encoding: .utf8) ?? ""
        }
    }

    static let registry = Registry()

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let stub = Self.registry.respond(to: request)
        guard let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: nil, headerFields: nil)
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
