import CoreUpload
import Foundation

/// Un origen de bytes por bloque: lee el rango del archivo (copia privada de lo elegido) y lo escribe en un archivo
/// temporal, porque las subidas en segundo plano de `URLSession` solo aceptan archivos como cuerpo. El archivo
/// temporal queda fuera de la copia de seguridad y con protección tras el primer desbloqueo (ADR-IOS-0009).
public struct FileBlockSource: Sendable {
    public let sourceFile: URL
    public let directory: URL

    public init(sourceFile: URL, directory: URL) {
        self.sourceFile = sourceFile
        self.directory = directory
    }

    func writeBlock(_ block: UploadBlock) throws -> URL {
        let fileManager = FileManager.default
        var directory = directory
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        let handle = try FileHandle(forReadingFrom: sourceFile)
        defer { try? handle.close() }
        try handle.seek(toOffset: UInt64(block.offset))
        let data = try handle.read(upToCount: Int(block.length)) ?? Data()
        let target = directory.appendingPathComponent("block-\(block.index).part")
        try data.write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return target
    }

    /// Borra los bloques temporales (al terminar, fallar, cancelar o cerrar sesión).
    public func purge() {
        try? FileManager.default.removeItem(at: directory)
    }
}

/// Subida de bloques con `URLSession` en segundo plano (ADR-IOS-0009): `isDiscretionary = false` y
/// `sessionSendsLaunchEvents`. La petición lleva SOLO la SAS (ni token de acceso ni cabeceras de la API).
/// Limitación conocida (nivel C, sin verificar en dispositivo): si la app muere con un bloque en vuelo, el resultado se
/// pierde y ese bloque se repite al reanudar. Los bloques ya registrados en `UploadState` no se repiten.
public final class BackgroundBlockTransport: NSObject, BlockTransport, @unchecked Sendable {
    private let source: FileBlockSource
    private let lock = NSLock()
    private var continuations: [Int: CheckedContinuation<Void, Error>] = [:]
    private var statusCodes: [Int: Int] = [:]
    private var session: URLSession?
    private let identifier: String

    public init(source: FileBlockSource, identifier: String = "com.venuenexa.pocios.upload") {
        self.source = source
        self.identifier = identifier
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    public func putBlock(_ block: UploadBlock, sas: URL) async throws {
        guard let session else { throw UploadError.failed }
        let file = try source.writeBlock(block)
        var request = URLRequest(url: try Self.blockURL(sas: sas, blockID: block.id))
        request.httpMethod = "PUT"
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        let task = session.uploadTask(with: request, fromFile: file)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lock.lock()
            continuations[task.taskIdentifier] = continuation
            lock.unlock()
            task.resume()
        }
    }

    public func putBlockList(ids: [String], sas: URL) async throws {
        var components = try Self.parse(sas)
        components.percentEncodedQueryItems =
            (components.percentEncodedQueryItems ?? []) + [URLQueryItem(name: "comp", value: "blocklist")]
        guard let url = components.url else { throw UploadError.failed }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        let body = "<?xml version=\"1.0\" encoding=\"utf-8\"?><BlockList>"
            + ids.map { "<Latest>\($0)</Latest>" }.joined() + "</BlockList>"
        do {
            let session = URLSession(configuration: .ephemeral)
            let (_, response) = try await session.upload(for: request, from: Data(body.utf8))
            try Self.check((response as? HTTPURLResponse)?.statusCode)
        } catch let error as UploadError {
            throw error
        } catch {
            throw UploadError.network
        }
    }

    private static func parse(_ sas: URL) throws -> URLComponents {
        guard let components = URLComponents(url: sas, resolvingAgainstBaseURL: false) else { throw UploadError.failed }
        return components
    }

    static func blockURL(sas: URL, blockID: String) throws -> URL {
        var components = try parse(sas)
        // La SAS ya viene codificada (su firma lleva `%2B`, `%2F`…): se conserva tal cual. Releerla con `queryItems` la
        // decodificaría y al volver a escribirla un `+` real pasaría a ser un espacio: el servidor respondería 403.
        components.percentEncodedQueryItems =
            (components.percentEncodedQueryItems ?? []) + [
                URLQueryItem(name: "comp", value: "block"),
                URLQueryItem(name: "blockid", value: Self.percentEncode(blockID)),
            ]
        guard let url = components.url else { throw UploadError.failed }
        return url
    }

    /// Codifica un valor para la query: solo quedan sin codificar los caracteres no reservados (RFC 3986).
    static func percentEncode(_ value: String) -> String {
        let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
    }

    static func check(_ status: Int?) throws {
        switch status {
        case 200, 201: return
        case 403, 401: throw UploadError.sasExpired
        default: throw UploadError.failed
        }
    }
}

extension BackgroundBlockTransport: URLSessionTaskDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let id = task.taskIdentifier
        lock.lock()
        let continuation = continuations.removeValue(forKey: id)
        lock.unlock()
        guard let continuation else { return }
        if error != nil {
            continuation.resume(throwing: UploadError.network)
            return
        }
        do {
            try Self.check((task.response as? HTTPURLResponse)?.statusCode)
            continuation.resume()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
