import Foundation

public enum AppDestination: Equatable, Sendable {
    case home
    case venue(id: String)
    case account
}

/// Universal links (ADR-IOS-0003): el prefijo de idioma (`/en`, `/es`) se ignora, así que `/en/venues/x`,
/// `/es/venues/x` y `/venues/x` abren el mismo destino. Los IDs se validan; el servidor autoriza el acceso.
public enum UniversalLinkRouter {
    private static let languagePrefixes: Set<String> = ["en", "es"]

    public static func destination(for url: URL) -> AppDestination? {
        var parts = url.pathComponents.filter { $0 != "/" }
        if let first = parts.first, languagePrefixes.contains(first) {
            parts.removeFirst()
        }
        switch parts.count {
        case 0:
            return .home
        case 1 where parts[0] == "account":
            return .account
        case 2 where parts[0] == "venues" && isValidID(parts[1]):
            return .venue(id: parts[1])
        default:
            return nil
        }
    }

    private static func isValidID(_ id: String) -> Bool {
        let allowedPunctuation: Set<Character> = ["-", "_"]
        return !id.isEmpty && id.count <= 64
            && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || allowedPunctuation.contains($0)) }
    }
}
