import CoreTesting
import Foundation
import Testing

@testable import CoreAttest

struct AttestedRequestSignerTests {
    private let body = Data("{\"venue\":\"x\"}".utf8)

    @Test func signsBookingsWithTheHashOfMethodPathAndBody() async throws {
        let service = FakeAttestationService(isSupported: true)
        let signer = AttestedRequestSigner(service: service, hasher: FakeHasher())
        let headers = try await signer.headers(operation: .booking, method: "post", path: "/v1/bookings", body: body)
        #expect(headers[AttestedRequestSigner.headerName] == Data("assertion".utf8).base64EncodedString())
        var material = Data("POST\n/v1/bookings\n".utf8)
        material.append(body)
        #expect(await service.receivedHashes == [FakeHasher().sha256(material)])
    }

    @Test func theSameRequestOnAnotherPathProducesAnotherHash() async throws {
        let service = FakeAttestationService(isSupported: true)
        let signer = AttestedRequestSigner(service: service, hasher: FakeHasher())
        _ = try await signer.headers(operation: .payment, method: "POST", path: "/v1/a", body: body)
        _ = try await signer.headers(operation: .payment, method: "POST", path: "/v1/b", body: body)
        let hashes = await service.receivedHashes
        #expect(hashes.count == 2)
        #expect(hashes[0] != hashes[1])
    }

    @Test func isOmittedWhenTheDeviceDoesNotSupportIt() async throws {
        let service = FakeAttestationService(isSupported: false)
        let signer = AttestedRequestSigner(service: service, hasher: FakeHasher())
        let headers = try await signer.headers(operation: .payment, method: "POST", path: "/v1/pay", body: body)
        #expect(headers.isEmpty)
        #expect(await service.receivedHashes.isEmpty)
    }

    @Test func ordinaryCallsCarryNoAssertion() async throws {
        let service = FakeAttestationService(isSupported: true)
        let signer = AttestedRequestSigner(service: service, hasher: FakeHasher())
        let headers = try await signer.headers(operation: .other, method: "GET", path: "/v1/venues", body: Data())
        #expect(headers.isEmpty)
    }

    @Test func everyOperationOfTheADRRequiresAttestation() {
        let required = AttestedOperation.allCases.filter(AttestedRequestSigner.requiresAttestation)
        #expect(Set(required).count == AttestedOperation.allCases.count - 1)
        #expect(!AttestedRequestSigner.requiresAttestation(.other))
    }
}
