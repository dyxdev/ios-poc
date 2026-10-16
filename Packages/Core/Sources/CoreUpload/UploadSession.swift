import Foundation

public enum UploadError: Error, Sendable, Equatable {
    /// La URL firmada (SAS) caducó o fue rechazada: hay que pedir otra y repetir ese bloque.
    case sasExpired
    case network
    case failed
}

/// El estado persistido de una subida. NO guarda la SAS ni ningún token (ADR-IOS-0009): solo qué bloques ya están.
public struct UploadState: Sendable, Equatable, Codable {
    public let fileID: String
    public let totalBytes: Int64
    public let blockSize: Int64
    public var completed: Set<Int>

    public init(fileID: String, totalBytes: Int64, blockSize: Int64, completed: Set<Int> = []) {
        self.fileID = fileID
        self.totalBytes = totalBytes
        self.blockSize = blockSize
        self.completed = completed
    }
}

public protocol BlockTransport: Sendable {
    func putBlock(_ block: UploadBlock, sas: URL) async throws
    func putBlockList(ids: [String], sas: URL) async throws
}

/// Sube los bloques que faltan: tras un corte de red o una nueva instancia de la app se reanuda sin repetir los que
/// ya están; si la SAS caduca pide otra y repite solo ese bloque. La petición lleva únicamente la SAS.
public actor UploadSession {
    private var state: UploadState
    private let transport: BlockTransport
    private let sasProvider: @Sendable () async throws -> URL
    private let persist: @Sendable (UploadState) async -> Void
    private let maxAttemptsPerBlock: Int

    public init(
        state: UploadState,
        transport: BlockTransport,
        sasProvider: @escaping @Sendable () async throws -> URL,
        persist: @escaping @Sendable (UploadState) async -> Void,
        maxAttemptsPerBlock: Int = 3
    ) {
        self.state = state
        self.transport = transport
        self.sasProvider = sasProvider
        self.persist = persist
        self.maxAttemptsPerBlock = maxAttemptsPerBlock
    }

    public var currentState: UploadState { state }

    public func run() async throws {
        let blocks = BlockPlanner.plan(totalBytes: state.totalBytes, blockSize: state.blockSize)
        var sas = try await sasProvider()
        for block in blocks where !state.completed.contains(block.index) {
            var attempts = 0
            while true {
                attempts += 1
                do {
                    try await transport.putBlock(block, sas: sas)
                    state.completed.insert(block.index)
                    await persist(state)
                    break
                } catch UploadError.sasExpired {
                    sas = try await sasProvider()
                    if attempts >= maxAttemptsPerBlock { throw UploadError.sasExpired }
                } catch {
                    if attempts >= maxAttemptsPerBlock { throw error }
                }
            }
        }
        try await transport.putBlockList(ids: blocks.map(\.id), sas: sas)
    }
}
