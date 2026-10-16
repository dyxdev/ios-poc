import CoreIdentity
import CoreModel
import CoreTesting
import Foundation
import Testing

@testable import CoreNetwork

private func lines(_ text: String) -> [String] {
    var decoder = SSELineDecoder()
    return text.utf8.compactMap { decoder.feed($0) }
}

struct SSELineDecoderTests {
    @Test func keepsEmptyLinesBecauseTheyEndAnEvent() {
        #expect(lines("data: a\n\ndata: b\n\n") == ["data: a", "", "data: b", ""])
    }

    @Test func handlesCRLF() {
        #expect(lines("id: 1\r\ndata: x\r\n\r\n") == ["id: 1", "data: x", ""])
    }

    @Test func aLineIsOnlyDeliveredWhenItsNewlineArrives() {
        #expect(lines("data: incompleta").isEmpty)
    }
}

struct SSEParserTests {
    private func parse(_ text: String) -> [SSEEvent] {
        var parser = SSEParser()
        return lines(text).compactMap { parser.feed(line: $0) }
    }

    @Test func parsesIDEventAndMultiLineData() {
        let events = parse("id: 7\nevent: booking\ndata: one\ndata: two\n\n")
        #expect(events == [SSEEvent(id: "7", event: "booking", data: "one\ntwo")])
    }

    @Test func defaultEventNameIsMessage() {
        #expect(parse("data: hola\n\n").first?.event == "message")
    }

    @Test func commentsAndHeartbeatsAreIgnored() {
        #expect(parse(": ping\n\ndata: x\n\n") == [SSEEvent(id: nil, event: "message", data: "x")])
    }

    @Test func aBlockWithoutDataProducesNoEvent() {
        #expect(parse("event: vacio\n\n").isEmpty)
    }

    @Test func remembersTheLastIDForReconnecting() {
        var parser = SSEParser()
        for line in lines("id: 1\ndata: a\n\nid: 2\ndata: b\n\n") { _ = parser.feed(line: line) }
        #expect(parser.lastEventID == "2")
    }

    @Test func removesOneLeadingSpaceOnly() {
        #expect(parse("data:  dos\n\n").first?.data == " dos")
        #expect(parse("data:sin\n\n").first?.data == "sin")
    }
}

struct SSEClientTests {
    @Test func reconnectsSendingLastEventIDAndDoesNotRepeatOrLoseEvents() async throws {
        let transport = FakeSSETransport(scripts: [
            .init(chunks: ["id: 1\ndata: a\n\n"], failure: .network),
            .init(chunks: ["id: 2\ndata: b\n\n"]),
        ])
        let client = SSEClient(transport: transport, maxRetries: 3, backoff: { _ in .zero }, sleep: { _ in })
        var received: [String] = []
        for try await event in client.events() {
            received.append(event.data)
            if received.count == 2 { break }
        }
        #expect(received == ["a", "b"])
        let ids = await transport.requestedLastEventIDs
        #expect(ids.count >= 2)
        #expect(ids[0] == nil)
        #expect(ids[1] == "1")
    }

    @Test func givesUpAfterTheMaximumNumberOfFailedReconnections() async {
        let failing = (0..<5).map { _ in FakeSSETransport.Script(chunks: [], failure: .network) }
        let client = SSEClient(
            transport: FakeSSETransport(scripts: failing),
            maxRetries: 2,
            backoff: { _ in .zero },
            sleep: { _ in }
        )
        var threw = false
        do {
            for try await _ in client.events() {}
        } catch {
            threw = true
        }
        #expect(threw)
    }
}

struct RetryPolicyTests {
    private let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1)

    @Test func rateLimitedWaitsForRetryAfter() {
        let decision = policy.decision(
            for: .rateLimited(retryAfter: 9, correlationID: nil),
            attempt: 0,
            isRead: true,
            hasIdempotencyKey: false
        )
        #expect(decision == .retry(after: 9))
    }

    @Test func conflictIsNeverRetried() {
        #expect(
            policy.decision(for: .conflict(correlationID: nil), attempt: 0, isRead: true, hasIdempotencyKey: true)
                == .doNotRetry
        )
    }

    @Test func aMutationWithoutAnIdempotencyKeyIsNeverRetried() {
        let unavailable = AppError.unavailable(reason: .server, correlationID: nil)
        #expect(policy.decision(for: unavailable, attempt: 0, isRead: false, hasIdempotencyKey: false) == .doNotRetry)
        let withKey = policy.decision(for: unavailable, attempt: 0, isRead: false, hasIdempotencyKey: true)
        #expect(withKey == .retry(after: 1))
    }

    @Test func readsBackOffExponentiallyAndStopAtTheMaximum() {
        let unavailable = AppError.unavailable(reason: .server, correlationID: nil)
        let second = policy.decision(for: unavailable, attempt: 1, isRead: true, hasIdempotencyKey: false)
        let exhausted = policy.decision(for: unavailable, attempt: 3, isRead: true, hasIdempotencyKey: false)
        #expect(second == .retry(after: 2))
        #expect(exhausted == .doNotRetry)
    }
}
