import Foundation

/// URL de reproducción HLS de Mux con el JWT como parámetro `token` (ADR-IOS-0029). El reproductor es AVPlayer
/// propio, sin Mux Player ni Mux Data. La URL no lleva el token de acceso de la sesión: solo el token de reproducción.
public enum SignedPlaybackURL {
    public static func make(playbackID: String, token: String?) -> URL? {
        guard isValidPlaybackID(playbackID) else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "stream.mux.com"
        components.path = "/\(playbackID).m3u8"
        if let token, !token.isEmpty {
            components.queryItems = [URLQueryItem(name: "token", value: token)]
        }
        return components.url
    }

    /// Los playback IDs de Mux son alfanuméricos: cualquier otra cosa (barras, puntos, espacios) se rechaza.
    static func isValidPlaybackID(_ id: String) -> Bool {
        !id.isEmpty && id.count <= 128 && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }
}

/// Clasifica los hosts de una captura de red: la condición de ADR-IOS-0029 es «0 peticiones a `*.litix.io` ni a
/// dominios no aprobados». La captura (mitmproxy) es externa a la app; esta lógica evalúa su resultado.
public enum NetworkEvidence {
    public static let forbiddenSuffixes = ["litix.io"]

    public static func violations(hosts: [String], approvedSuffixes: [String]) -> [String] {
        hosts.filter { host in
            let lower = host.lowercased()
            let forbidden = forbiddenSuffixes.contains { lower == $0 || lower.hasSuffix("." + $0) }
            let approved = approvedSuffixes.contains { lower == $0 || lower.hasSuffix("." + $0) }
            return forbidden || !approved
        }
    }
}
