#if DEBUG
    import CoreContext
    import CoreIdentity
    import Foundation

    /// Argumentos de lanzamiento SOLO de debug, para sacar capturas reales de cada pantalla en CI sin tocar la interfaz
    /// (`simctl` no puede pulsar). `UserDefaults` lee `-VNScreen valor` de los argumentos de lanzamiento. No existen en
    /// release.
    ///   -VNScreen welcome|home|detail|account|diagnostics|owner|admin
    ///   -VNSignedIn 1     deja una sesión FALSA (sin refresh token, sin servidor) para ver pantallas con sesión
    enum LaunchOverrides {
        static var screen: String? { UserDefaults.standard.string(forKey: "VNScreen") }

        /// `owner` y `admin` solo existen con sesión (las capacidades simuladas la exigen).
        static var wantsSession: Bool {
            UserDefaults.standard.bool(forKey: "VNSignedIn") || screen == "owner" || screen == "admin"
        }

        static var fakeTokens: Tokens {
            Tokens(
                accessToken: "captura-sin-valor",
                refreshToken: nil,
                idToken: nil,
                expiresAt: Date().addingTimeInterval(3600)
            )
        }

        static var context: UserContext? {
            switch screen {
            case "owner": .owner
            case "admin": .admin
            default: nil
            }
        }
    }
#endif
