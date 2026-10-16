import Foundation

public struct UploadBlock: Sendable, Equatable, Codable {
    public let index: Int
    /// Identificador del bloque (Base64 de un número de longitud fija, como exige `Put Block`).
    public let id: String
    public let offset: Int64
    public let length: Int64
}

/// Reparte un archivo en bloques para la subida por `Put Block` y `Put Block List` (ADR-IOS-0009, decisión de Andy
/// del 2026-10-12: por bloques en los tres clientes). El tamaño del bloque lo fija la configuración, no este tipo.
public enum BlockPlanner {
    public static func plan(totalBytes: Int64, blockSize: Int64) -> [UploadBlock] {
        guard totalBytes > 0, blockSize > 0 else { return [] }
        var blocks: [UploadBlock] = []
        var offset: Int64 = 0
        var index = 0
        while offset < totalBytes {
            let length = min(blockSize, totalBytes - offset)
            blocks.append(UploadBlock(index: index, id: blockID(index), offset: offset, length: length))
            offset += length
            index += 1
        }
        return blocks
    }

    /// Todos los IDs de un mismo archivo deben tener la misma longitud: 6 dígitos con ceros a la izquierda.
    public static func blockID(_ index: Int) -> String {
        let padded = String(format: "%06d", index)
        return Data(padded.utf8).base64EncodedString()
    }
}
