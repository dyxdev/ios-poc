import Foundation
import Testing

@testable import CoreModel

struct AppErrorTests {
    @Test func mapsStatusCodesToFixedCases() {
        #expect(AppError.from(status: 401, code: nil) == .unauthorized(correlationID: nil))
        #expect(AppError.from(status: 403, code: nil) == .forbidden(correlationID: nil))
        #expect(AppError.from(status: 404, code: nil) == .notFound(correlationID: nil))
        #expect(AppError.from(status: 409, code: nil) == .conflict(correlationID: nil))
        #expect(AppError.from(status: 422, code: nil) == .validation(correlationID: nil))
        #expect(AppError.from(status: 503, code: nil) == .unavailable(reason: .server, correlationID: nil))
    }

    @Test func stepUpComesFromTheBusinessCodeNotJustTheStatus() {
        #expect(AppError.from(status: 403, code: "step-up-required") == .stepUpRequired(correlationID: nil))
        #expect(AppError.from(status: 403, code: "other") == .forbidden(correlationID: nil))
    }

    @Test func updateRequiredByCodeOrByStatus() {
        #expect(AppError.from(status: 400, code: "update-required") == .updateRequired(correlationID: nil))
        #expect(AppError.from(status: 426, code: nil) == .updateRequired(correlationID: nil))
    }

    @Test func rateLimitedCarriesRetryAfterAndTheCorrelationID() {
        let error = AppError.from(status: 429, code: nil, retryAfter: 7, correlationID: "abc")
        #expect(error == .rateLimited(retryAfter: 7, correlationID: "abc"))
        #expect(error.correlationID == "abc")
    }

    @Test func unknownStatusNeverBreaks() {
        #expect(AppError.from(status: 599, code: "whatever", correlationID: "x") == .unexpected(correlationID: "x"))
    }
}

struct ImageRenditionTests {
    @Test func picksTheSmallestWidthThatCoversTheRealPixels() {
        #expect(ImageRendition.width(forPoints: 100, scale: 3) == 320)
        #expect(ImageRendition.width(forPoints: 214, scale: 3) == 960)
        #expect(ImageRendition.width(forPoints: 160, scale: 2) == 320)
        #expect(ImageRendition.width(forPoints: 320, scale: 2) == 640)
    }

    @Test func neverAsksForMoreThanTheLargest() {
        #expect(ImageRendition.width(forPoints: 1000, scale: 3) == 1440)
    }
}

struct BroadcasterTests {
    @Test func deliversTheCurrentValueFirstAndThenChanges() async {
        let broadcaster = Broadcaster(1)
        var iterator = await broadcaster.updates().makeAsyncIterator()
        #expect(await iterator.next() == 1)
        await broadcaster.send(2)
        #expect(await iterator.next() == 2)
        #expect(await broadcaster.current == 2)
    }
}
