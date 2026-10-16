import CoreConsent
import CoreContext
import CoreIdentity
import CoreNetwork
import CoreAttest
import CoreUpload
import Foundation

// Fakes por protocolo, sin librerías de mocking (ADR-IOS-0015). Los usan las pruebas de todos los paquetes.

public actor InMemoryTokenStore: TokenStore {
    private var tokens: Tokens?
    public private(set) var clearCount = 0

    public init(_ tokens: Tokens? = nil) {
        self.tokens = tokens
    }

    public func read() async throws -> Tokens? { tokens }

    public func write(_ tokens: Tokens) async throws {
        self.tokens = tokens
    }

    public func clear() async {
        tokens = nil
        clearCount += 1
    }

    public var stored: Tokens? { tokens }
}

public actor FakeAuthBackend: AuthBackend {
    public private(set) var refreshCalls = 0
    public private(set) var revokedTokens: [String] = []
    public private(set) var endSessionCalls = 0
    private var refreshResult: Result<Tokens, IdentityError>
    private let delay: Duration
    private let endSession: URL?

    public init(
        refreshResult: Result<Tokens, IdentityError>,
        delay: Duration = .zero,
        endSession: URL? = nil
    ) {
        self.refreshResult = refreshResult
        self.delay = delay
        self.endSession = endSession
    }

    public func setRefreshResult(_ result: Result<Tokens, IdentityError>) {
        refreshResult = result
    }

    public func refresh(refreshToken: String) async throws -> Tokens {
        refreshCalls += 1
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        return try refreshResult.get()
    }

    public func revoke(refreshToken: String) async throws {
        revokedTokens.append(refreshToken)
    }

    public func endSessionURL(idToken: String?) async throws -> URL? {
        endSessionCalls += 1
        return endSession
    }
}

public actor InMemoryConsentStore: ConsentStore {
    private var value: Bool
    public private(set) var writes: [Bool] = []

    public init(_ value: Bool = false) {
        self.value = value
    }

    public func read() async -> Bool { value }

    public func write(_ granted: Bool) async {
        value = granted
        writes.append(granted)
    }
}

public actor FakeAnalyticsSDK: AnalyticsSDK {
    public private(set) var startCount = 0
    public private(set) var stopCount = 0
    public private(set) var resetCount = 0

    public init() {}

    public func start() async { startCount += 1 }
    public func stop() async { stopCount += 1 }
    public func resetIdentity() async { resetCount += 1 }
}

public actor InMemoryContextPreferences: ContextPreferences {
    private var last: String?
    private var seen: Set<String> = []

    public init() {}

    public func lastContext() async -> String? { last }

    public func setLastContext(_ value: String) async {
        last = value
    }

    public func seenContexts() async -> Set<String> { seen }

    public func markSeen(_ values: Set<String>) async {
        seen.formUnion(values)
    }

    public func clearContextState() async {
        last = nil
        seen = []
    }
}

/// Un servidor SSE falso: cada conexión sigue un guion (bytes y, al final, un fallo o un cierre limpio) y se anota
/// el `Last-Event-ID` que envió el cliente.
public actor FakeSSETransport: SSETransport {
    public struct Script: Sendable {
        public var chunks: [String]
        public var failure: IdentityError?

        public init(chunks: [String], failure: IdentityError? = nil) {
            self.chunks = chunks
            self.failure = failure
        }
    }

    private var scripts: [Script]
    public private(set) var requestedLastEventIDs: [String?] = []

    public init(scripts: [Script]) {
        self.scripts = scripts
    }

    public func connect(lastEventID: String?) async throws -> AsyncThrowingStream<UInt8, Error> {
        requestedLastEventIDs.append(lastEventID)
        let script = scripts.isEmpty ? Script(chunks: []) : scripts.removeFirst()
        return AsyncThrowingStream { continuation in
            for chunk in script.chunks {
                for byte in chunk.utf8 {
                    continuation.yield(byte)
                }
            }
            if let failure = script.failure {
                continuation.finish(throwing: failure)
            } else {
                continuation.finish()
            }
        }
    }
}

public actor FakeBlockTransport: BlockTransport {
    public private(set) var putBlockCalls: [Int] = []
    public private(set) var sasUsed: [URL] = []
    public private(set) var blockListIDs: [String]?
    private var failures: [Int: [UploadError]]

    /// `failures[3] = [.network, .sasExpired]` hace fallar el bloque 3 en sus dos primeros intentos.
    public init(failures: [Int: [UploadError]] = [:]) {
        self.failures = failures
    }

    public func putBlock(_ block: UploadBlock, sas: URL) async throws {
        putBlockCalls.append(block.index)
        sasUsed.append(sas)
        if var queue = failures[block.index], !queue.isEmpty {
            let next = queue.removeFirst()
            failures[block.index] = queue
            throw next
        }
    }

    public func putBlockList(ids: [String], sas: URL) async throws {
        blockListIDs = ids
    }
}

public struct FakeHasher: RequestHasher {
    public init() {}

    /// No es SHA-256: es determinista y reversible, para comprobar QUÉ se firma.
    public func sha256(_ data: Data) -> Data {
        var out = Data("H(".utf8)
        out.append(data)
        out.append(Data(")".utf8))
        return out
    }
}

public actor FakeAttestationService: AttestationService {
    public nonisolated let isSupported: Bool
    public private(set) var receivedHashes: [Data] = []

    public init(isSupported: Bool) {
        self.isSupported = isSupported
    }

    public func assertion(clientDataHash: Data) async throws -> Data {
        receivedHashes.append(clientDataHash)
        return Data("assertion".utf8)
    }
}

/// Espera, sin dormir de más, a que una condición asíncrona se cumpla (hasta `timeout`). Para pruebas de flujos
/// que se propagan por tareas: evita depender de un número fijo de cesiones del hilo.
public func eventually(
    timeout: Duration = .seconds(2),
    _ condition: @Sendable () async -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return await condition()
}

public actor InMemoryOnboardingStore: OnboardingStore {
    private var seen: Bool

    public init(seen: Bool = false) {
        self.seen = seen
    }

    public func welcomeSeen() async -> Bool { seen }
    public func setWelcomeSeen() async { seen = true }
    public func reset() async { seen = false }
}
