import CoreApple
import CoreIdentity
import Foundation

/// Login y logout contra Keycloak (AppAuth y el navegador del sistema). Está separado de `AppServices` para que los
/// modelos reciban estos cierres al construirse, sin singletons ni referencias circulares.
@MainActor
final class SessionActions {
    private let identity: IdentityManager
    private let signInFlow: AppAuthSignIn?
    private let endSession = EndSessionPresenter()

    init(identity: IdentityManager, configuration: OIDCConfiguration?) {
        self.identity = identity
        signInFlow = configuration.map(AppAuthSignIn.init)
    }

    func signIn(idpHint: String?) async {
        guard let signInFlow else {
            await identity.signInFailed(.notConfigured)
            return
        }
        guard let anchor = PresentationAnchor.topViewController() else {
            await identity.signInFailed(.failed)
            return
        }
        do {
            let tokens = try await signInFlow.signIn(presenting: anchor, idpHint: idpHint)
            try await identity.completeSignIn(tokens)
        } catch let error as IdentityError {
            await identity.signInFailed(error)
        } catch {
            await identity.signInFailed(.failed)
        }
    }

    /// La limpieza de lo local la hace `SessionCleanup` al ver la transición iniciada → cerrada; aquí solo se revoca,
    /// se cierra la sesión local y se abre el cierre SSO.
    func signOut() async {
        if let url = await identity.signOut() {
            await endSession.present(url: url, callbackScheme: Configuration.redirectScheme)
        }
    }
}
