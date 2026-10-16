import CoreTesting
import Foundation
import Testing

@testable import CoreUpload

private func testURL(_ text: String) -> URL {
    guard let url = URL(string: text) else { preconditionFailure("URL de prueba inválida: \(text)") }
    return url
}

private let sasOne = testURL("https://account.blob.example/c/f?sv=1&sig=AAA")
private let sasTwo = testURL("https://account.blob.example/c/f?sv=1&sig=BBB")

private actor Persisted {
    private(set) var states: [UploadState] = []
    func record(_ state: UploadState) { states.append(state) }
}

struct BlockPlannerTests {
    @Test func splitsInFullBlocksAndALastShortOne() {
        let blocks = BlockPlanner.plan(totalBytes: 25, blockSize: 10)
        #expect(blocks.map(\.length) == [10, 10, 5])
        #expect(blocks.map(\.offset) == [0, 10, 20])
    }

    @Test func blockIDsHaveTheSameLengthAndAreUnique() {
        let blocks = BlockPlanner.plan(totalBytes: 1500, blockSize: 1)
        #expect(Set(blocks.map(\.id)).count == blocks.count)
        #expect(Set(blocks.map { $0.id.count }).count == 1)
    }

    @Test func emptyInputsGiveNoBlocks() {
        #expect(BlockPlanner.plan(totalBytes: 0, blockSize: 10).isEmpty)
        #expect(BlockPlanner.plan(totalBytes: 10, blockSize: 0).isEmpty)
    }
}

struct UploadSessionTests {
    private func state(done: Set<Int> = []) -> UploadState {
        UploadState(fileID: "f1", totalBytes: 40, blockSize: 10, completed: done)
    }

    @Test func uploadsEveryBlockThenCommitsTheListInOrder() async throws {
        let transport = FakeBlockTransport()
        let session = UploadSession(state: state(), transport: transport, sasProvider: { sasOne }, persist: { _ in })
        try await session.run()
        #expect(await transport.putBlockCalls == [0, 1, 2, 3])
        #expect(await transport.blockListIDs == BlockPlanner.plan(totalBytes: 40, blockSize: 10).map(\.id))
    }

    @Test func resumingDoesNotRepeatBlocksThatAreAlreadyThere() async throws {
        let transport = FakeBlockTransport()
        let session = UploadSession(
            state: state(done: [0, 1]),
            transport: transport,
            sasProvider: { sasOne },
            persist: { _ in }
        )
        try await session.run()
        #expect(await transport.putBlockCalls == [2, 3])
    }

    @Test func aNetworkCutIsRetriedOnTheSameBlockWithoutRepeatingTheOthers() async throws {
        let transport = FakeBlockTransport(failures: [2: [.network]])
        let session = UploadSession(state: state(), transport: transport, sasProvider: { sasOne }, persist: { _ in })
        try await session.run()
        #expect(await transport.putBlockCalls == [0, 1, 2, 2, 3])
    }

    @Test func anExpiredSASIsRenewedAndOnlyThatBlockIsRepeated() async throws {
        let transport = FakeBlockTransport(failures: [1: [.sasExpired]])
        let counter = Persisted()
        let provided = SASSequence([sasOne, sasTwo])
        let session = UploadSession(
            state: state(),
            transport: transport,
            sasProvider: { await provided.next() },
            persist: { await counter.record($0) }
        )
        try await session.run()
        #expect(await transport.putBlockCalls == [0, 1, 1, 2, 3])
        #expect(await transport.sasUsed.last == sasTwo)
    }

    @Test func givesUpAfterTheMaximumAttemptsOnABlock() async {
        let transport = FakeBlockTransport(failures: [0: [.network, .network, .network]])
        let session = UploadSession(state: state(), transport: transport, sasProvider: { sasOne }, persist: { _ in })
        await #expect(throws: UploadError.network) { try await session.run() }
    }

    @Test func thePersistedStateNeverContainsTheSASOrAToken() async throws {
        let transport = FakeBlockTransport()
        let counter = Persisted()
        let session = UploadSession(
            state: state(),
            transport: transport,
            sasProvider: { sasOne },
            persist: { await counter.record($0) }
        )
        try await session.run()
        let states = await counter.states
        #expect(states.last?.completed == [0, 1, 2, 3])
        let json = try String(decoding: JSONEncoder().encode(states.last), as: UTF8.self)
        #expect(!json.contains("sig="))
        #expect(!json.lowercased().contains("sas"))
        #expect(!json.lowercased().contains("token"))
    }
}

/// Entrega una URL firmada distinta cada vez que se pide (la última se repite).
private actor SASSequence {
    private var urls: [URL]
    init(_ urls: [URL]) { self.urls = urls }
    func next() -> URL { urls.count > 1 ? urls.removeFirst() : urls[0] }
}
