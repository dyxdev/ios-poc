import Foundation
import Testing

@testable import CoreLinks

struct UniversalLinkRouterTests {
    private func route(_ text: String) -> AppDestination? {
        URL(string: text).flatMap(UniversalLinkRouter.destination(for:))
    }

    @Test func languagePrefixIsIgnored() {
        let expected = AppDestination.venue(id: "loft-gracia")
        #expect(route("https://venuenexa.example/venues/loft-gracia") == expected)
        #expect(route("https://venuenexa.example/en/venues/loft-gracia") == expected)
        #expect(route("https://venuenexa.example/es/venues/loft-gracia") == expected)
    }

    @Test func rootAndAccountRoutes() {
        #expect(route("https://venuenexa.example/") == .home)
        #expect(route("https://venuenexa.example/es") == .home)
        #expect(route("https://venuenexa.example/en/account") == .account)
    }

    @Test func unknownPathsAndInvalidIDsDoNotOpenAnything() {
        #expect(route("https://venuenexa.example/admin/users") == nil)
        #expect(route("https://venuenexa.example/venues/a%20b") == nil)
        #expect(route("https://venuenexa.example/venues/x/extra") == nil)
        #expect(route("https://venuenexa.example/fr/venues/loft") == nil)
    }
}
