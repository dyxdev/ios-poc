import Foundation
import Testing

@testable import CorePlayback

struct SignedPlaybackURLTests {
    @Test func buildsTheMuxHLSURLWithTheTokenAsAQueryParameter() {
        let url = SignedPlaybackURL.make(playbackID: "abc123", token: "jwt.value.here")
        #expect(url?.absoluteString == "https://stream.mux.com/abc123.m3u8?token=jwt.value.here")
    }

    @Test func aPublicPlaybackHasNoQuery() {
        let url = SignedPlaybackURL.make(playbackID: "abc123", token: nil)
        #expect(url?.absoluteString == "https://stream.mux.com/abc123.m3u8")
    }

    @Test func rejectsPlaybackIDsThatCouldChangeThePath() {
        #expect(SignedPlaybackURL.make(playbackID: "../etc", token: nil) == nil)
        #expect(SignedPlaybackURL.make(playbackID: "a/b", token: nil) == nil)
        #expect(SignedPlaybackURL.make(playbackID: "", token: nil) == nil)
    }

    @Test func theURLNeverCarriesTheSessionAccessToken() {
        // El único token que viaja es el de reproducción que emite la API: se comprueba que no hay más parámetros.
        let url = SignedPlaybackURL.make(playbackID: "abc", token: "t")
        let names = URLComponents(url: url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?
            .queryItems?.map(\.name)
        #expect(names == ["token"])
    }
}

struct NetworkEvidenceTests {
    private let approved = ["mux.com", "unsplash.com", "keycloak.example"]

    @Test func cleanCaptureHasNoViolations() {
        let hosts = ["stream.mux.com", "images.unsplash.com", "keycloak.example"]
        #expect(NetworkEvidence.violations(hosts: hosts, approvedSuffixes: approved).isEmpty)
    }

    @Test func litixAndUnapprovedHostsAreViolations() {
        let hosts = ["stream.mux.com", "img.litix.io", "tracker.example", "LITIX.io"]
        let violations = NetworkEvidence.violations(hosts: hosts, approvedSuffixes: approved)
        #expect(violations == ["img.litix.io", "tracker.example", "LITIX.io"])
    }

    @Test func aHostThatOnlyEndsLikeAnApprovedOneIsNotApproved() {
        #expect(NetworkEvidence.violations(hosts: ["evilmux.com"], approvedSuffixes: approved) == ["evilmux.com"])
    }
}
