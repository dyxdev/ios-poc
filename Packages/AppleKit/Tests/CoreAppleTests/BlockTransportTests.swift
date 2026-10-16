import CoreUpload
import Foundation
import Testing

@testable import CoreApple

struct BlockURLTests {
    private let sas = URL(string: "https://account.blob.core.windows.net/c/b?sv=2024&sig=abc%2Bdef&se=2026")!

    @Test func addsTheBlockParametersAndKeepsTheSasUntouched() throws {
        let url = try BackgroundBlockTransport.blockURL(sas: sas, blockID: "AAAA")
        let query = url.query ?? ""
        #expect(query.hasPrefix("sv=2024&sig=abc%2Bdef&se=2026"))
        #expect(query.contains("comp=block"))
        #expect(query.contains("blockid=AAAA"))
        #expect(url.host == "account.blob.core.windows.net")
        #expect(url.path == "/c/b")
    }

    @Test func theSasSignatureKeepsItsPercentEncodingSoAPlusIsNeverReadAsASpace() throws {
        let url = try BackgroundBlockTransport.blockURL(sas: sas, blockID: "AAAA")
        #expect(url.absoluteString.contains("sig=abc%2Bdef"))
        #expect(!url.absoluteString.contains("sig=abc+def"))
    }

    @Test func theBlockIDIsPercentEncodedBecauseBase64UsesPlusSlashAndEquals() throws {
        let url = try BackgroundBlockTransport.blockURL(sas: sas, blockID: "a+b/c==")
        #expect((url.query ?? "").contains("blockid=a%2Bb%2Fc%3D%3D"))
    }

    @Test func statusCodesMapToUploadErrors() throws {
        try BackgroundBlockTransport.check(201)
        try BackgroundBlockTransport.check(200)
        #expect(throws: UploadError.sasExpired) { try BackgroundBlockTransport.check(403) }
        #expect(throws: UploadError.sasExpired) { try BackgroundBlockTransport.check(401) }
        #expect(throws: UploadError.failed) { try BackgroundBlockTransport.check(500) }
        #expect(throws: UploadError.failed) { try BackgroundBlockTransport.check(nil) }
    }
}

struct FileBlockSourceTests {
    private func makeSource(bytes: Int) throws -> (FileBlockSource, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("source.bin")
        try Data((0..<bytes).map { UInt8($0 % 251) }).write(to: file)
        return (FileBlockSource(sourceFile: file, directory: root.appendingPathComponent("blocks")), root)
    }

    @Test func writesExactlyTheRangeOfEachBlock() throws {
        let (source, root) = try makeSource(bytes: 1000)
        defer { try? FileManager.default.removeItem(at: root) }
        let blocks = BlockPlanner.plan(totalBytes: 1000, blockSize: 400)
        #expect(blocks.count == 3)
        for block in blocks {
            let written = try Data(contentsOf: try source.writeBlock(block))
            let all = (0..<1000).map { UInt8($0 % 251) }
            let expected = Data(all[Int(block.offset)..<Int(block.offset + block.length)])
            #expect(written == expected)
        }
    }

    @Test func theTemporaryBlocksAreExcludedFromBackupAndPurgeRemovesThem() throws {
        let (source, root) = try makeSource(bytes: 10)
        defer { try? FileManager.default.removeItem(at: root) }
        let block = try #require(BlockPlanner.plan(totalBytes: 10, blockSize: 10).first)
        _ = try source.writeBlock(block)
        let values = try source.directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
        source.purge()
        #expect(!FileManager.default.fileExists(atPath: source.directory.path))
    }
}
