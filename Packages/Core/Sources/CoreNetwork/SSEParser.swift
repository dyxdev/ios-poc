import Foundation

public struct SSEEvent: Sendable, Equatable {
    public let id: String?
    public let event: String
    public let data: String

    public init(id: String?, event: String, data: String) {
        self.id = id
        self.event = event
        self.data = data
    }
}

/// Decodifica bytes en líneas CONSERVANDO las líneas vacías. Es imprescindible: en SSE la línea vacía es la que
/// cierra el evento, y `URLSession.AsyncBytes.lines` no entrega las líneas vacías (por eso no se usa).
public struct SSELineDecoder: Sendable {
    private var buffer: [UInt8] = []

    public init() {}

    /// Alimenta un byte; devuelve una línea completa (sin `\n` ni `\r` final) cuando llega `\n`.
    public mutating func feed(_ byte: UInt8) -> String? {
        guard byte == 0x0A else {
            buffer.append(byte)
            return nil
        }
        if buffer.last == 0x0D {
            buffer.removeLast()
        }
        // `buffer` es [UInt8], no Data: `String(decoding:)` sustituye los bytes inválidos en vez de devolver nil, y una
        // línea perdida se leería como línea vacía (fin de evento).
        // swiftlint:disable:next optional_data_string_conversion
        let line = String(decoding: buffer, as: UTF8.self)
        buffer.removeAll(keepingCapacity: true)
        return line
    }
}

/// Parser de Server-Sent Events (ADR-IOS-0028): `id`, `event` y `data` (varias líneas), comentarios (`:`, el
/// latido de 30 s) y la línea vacía como fin de evento. Recuerda el último `id` para reconectar con `Last-Event-ID`.
public struct SSEParser: Sendable {
    public private(set) var lastEventID: String?
    private var dataLines: [String] = []
    private var eventName = "message"
    private var pendingID: String?

    public init() {}

    /// Devuelve un evento cuando la línea vacía cierra uno con datos.
    public mutating func feed(line: String) -> SSEEvent? {
        if line.isEmpty {
            return dispatch()
        }
        if line.hasPrefix(":") {
            return nil
        }
        let field: String
        var value: String
        if let colon = line.firstIndex(of: ":") {
            field = String(line[..<colon])
            value = String(line[line.index(after: colon)...])
            if value.hasPrefix(" ") {
                value.removeFirst()
            }
        } else {
            field = line
            value = ""
        }
        switch field {
        case "data":
            dataLines.append(value)
        case "event":
            eventName = value
        case "id":
            if !value.contains("\u{0}") {
                pendingID = value
                lastEventID = value
            }
        default:
            break
        }
        return nil
    }

    private mutating func dispatch() -> SSEEvent? {
        defer {
            dataLines = []
            eventName = "message"
            pendingID = nil
        }
        guard !dataLines.isEmpty else { return nil }
        return SSEEvent(id: pendingID, event: eventName, data: dataLines.joined(separator: "\n"))
    }
}
