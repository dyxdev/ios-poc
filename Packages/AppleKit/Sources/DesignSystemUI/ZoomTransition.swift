#if canImport(SwiftUI)
    import SwiftUI

    private struct ZoomNamespaceKey: EnvironmentKey {
        static let defaultValue: Namespace.ID? = nil
    }

    extension EnvironmentValues {
        /// El espacio de nombres de la transición compartida; lo ofrece la raíz de la app (como
        /// `LocalSharedTransitionScope`
        /// en Android). Sin él, las fotos no se comparten (previews, pruebas).
        public var zoomNamespace: Namespace.ID? {
            get { self[ZoomNamespaceKey.self] }
            set { self[ZoomNamespaceKey.self] = newValue }
        }
    }

    private struct ZoomSource: ViewModifier {
        let id: String
        @Environment(\.zoomNamespace) private var namespace

        func body(content: Content) -> some View {
            if #available(iOS 18.0, *), let namespace {
                content.matchedTransitionSource(id: id, in: namespace)
            } else {
                content
            }
        }
    }

    private struct ZoomDestination: ViewModifier {
        let id: String
        @Environment(\.zoomNamespace) private var namespace

        func body(content: Content) -> some View {
            if #available(iOS 18.0, *), let namespace {
                content.navigationTransition(.zoom(sourceID: id, in: namespace))
            } else {
                content
            }
        }
    }

    extension View {
        /// La tarjeta desde la que «viaja» la foto al detalle. La clave debe ser única por tarjeta visible (un mismo
        /// venue sale en el carrusel y en la lista).
        public func zoomSource(id: String) -> some View { modifier(ZoomSource(id: id)) }

        /// La pantalla de destino de la transición. Con iOS 17 se usa la transición normal de `NavigationStack`.
        public func zoomDestination(id: String) -> some View { modifier(ZoomDestination(id: id)) }
    }
#endif
