#if canImport(UIKit)
    @preconcurrency import AppAuth
    import CoreIdentity
    import Foundation
    import UIKit

    /// Login interactivo con AppAuth-iOS (ADR-IOS-0007): Authorization Code con PKCE S256 en
    /// `ASWebAuthenticationSession`. Google (y Apple) van por el brokering de Keycloak con `kc_idp_hint`; la
    /// vinculación de cuentas nunca es automática. AppAuth usa callbacks: aquí se envuelven en `async`.
    /// Sin verificar: los nombres exactos de la API de AppAuth 3.0 se tomaron de su README, no se compilaron.
    @MainActor
    public final class AppAuthSignIn {
        private var currentFlow: OIDExternalUserAgentSession?
        private let configuration: OIDCConfiguration

        public init(configuration: OIDCConfiguration) {
            self.configuration = configuration
        }

        public func signIn(presenting viewController: UIViewController, idpHint: String? = nil) async throws -> Tokens {
            let service = try await discover()
            let request = OIDAuthorizationRequest(
                configuration: service,
                clientId: configuration.clientID,
                clientSecret: nil,
                scopes: configuration.scopes,
                redirectURL: configuration.redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: idpHint.map { ["kc_idp_hint": $0] }
            )
            return try await withCheckedThrowingContinuation { continuation in
                currentFlow = OIDAuthState.authState(
                    byPresenting: request,
                    presenting: viewController
                ) { state, error in
                    if let tokens = Self.tokens(from: state) {
                        continuation.resume(returning: tokens)
                    } else {
                        continuation.resume(throwing: Self.map(error))
                    }
                }
            }
        }

        private func discover() async throws -> OIDServiceConfiguration {
            try await withCheckedThrowingContinuation { continuation in
                OIDAuthorizationService.discoverConfiguration(forIssuer: configuration.issuer) { service, _ in
                    if let service {
                        continuation.resume(returning: service)
                    } else {
                        continuation.resume(throwing: IdentityError.network)
                    }
                }
            }
        }

        nonisolated private static func tokens(from state: OIDAuthState?) -> Tokens? {
            guard let response = state?.lastTokenResponse, let access = response.accessToken else { return nil }
            return Tokens(
                accessToken: access,
                refreshToken: response.refreshToken,
                idToken: response.idToken,
                expiresAt: response.accessTokenExpirationDate
            )
        }

        nonisolated private static func map(_ error: Error?) -> IdentityError {
            guard let error = error as NSError? else { return .failed }
            if error.domain == OIDGeneralErrorDomain,
                error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
            {
                return .canceled
            }
            return .failed
        }
    }

    /// El `UIViewController` desde el que presentar el navegador del sistema (el de la ventana activa).
    @MainActor
    public enum PresentationAnchor {
        public static func topViewController() -> UIViewController? {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            var top = scene?.keyWindow?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }
    }
#endif
