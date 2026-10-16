#if canImport(AuthenticationServices) && canImport(UIKit)
    import AuthenticationServices
    import UIKit

    /// Abre la URL de cierre de sesión SSO de Keycloak en `ASWebAuthenticationSession` (comparte las cookies del
    /// navegador del sistema con el login, ADR-IOS-0007). El resultado no importa: la sesión local ya está cerrada y
    /// si la persona cancela solo queda viva la cookie SSO (se anota como límite conocido).
    @MainActor
    public final class EndSessionPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
        private var session: ASWebAuthenticationSession?

        public func present(url: URL, callbackScheme: String) async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { _, _ in
                    continuation.resume()
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                self.session = session
                if !session.start() {
                    continuation.resume()
                }
            }
            session = nil
        }

        public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            PresentationAnchor.topViewController()?.view.window ?? ASPresentationAnchor()
        }
    }
#endif
