import CoreApple
import Foundation

/// Configuración de identidad. El emisor de Keycloak no se guarda en el código: viene del `Info.plist` (clave
/// `VNKeycloakIssuer`, vacía por defecto) o de la variable de entorno `VN_KEYCLOAK_ISSUER` al lanzar desde Xcode.
/// Sin emisor, el login responde «no configurado» en vez de fallar (ADR-IOS-0007). ATS sin excepciones: todo HTTPS.
enum Configuration {
    /// Hosts aprobados para la evidencia de red (ADR-IOS-0029). El de Keycloak se suma en tiempo de ejecución.
    static let approvedHostSuffixes = [
        "stream.mux.com", "image.mux.com", "images.unsplash.com", "mux.com",
    ]

    static var redirectScheme: String {
        redirectURI?.scheme ?? "com.venuenexa.pocios"
    }

    static var redirectURI: URL? {
        string("VNRedirectURI", env: "VN_REDIRECT_URI").flatMap(URL.init(string:))
    }

    static var oidc: OIDCConfiguration? {
        guard let issuer = string("VNKeycloakIssuer", env: "VN_KEYCLOAK_ISSUER").flatMap(URL.init(string:)),
            issuer.scheme == "https",
            let clientID = string("VNKeycloakClientID", env: "VN_KEYCLOAK_CLIENT_ID"),
            let redirect = redirectURI
        else { return nil }
        return OIDCConfiguration(issuer: issuer, clientID: clientID, redirectURI: redirect)
    }

    private static func string(_ plistKey: String, env: String) -> String? {
        let fromEnvironment = ProcessInfo.processInfo.environment[env]
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String
        return [fromEnvironment, fromPlist].compactMap { $0 }.first { !$0.isEmpty }
    }
}
