import AppStrings
import ContextUI
import CoreContext
import CoreLinks
import CoreVenues
import DesignSystemUI
import DesignTokens
import FeatureAccount
import FeatureAdmin
import FeatureDetail
import FeatureHome
import FeatureOwner
import SwiftUI

/// Rutas de las pilas. La clave compartida viaja con la ruta para la transición de zoom de la foto.
enum Route: Hashable {
    case venue(id: String, sharedKey: String)
    case diagnostics
}

enum AppTab: Hashable {
    case home, owner, admin, account
}

/// Raíz: bienvenida solo la primera vez, después pestañas según el contexto activo. Cambiar de contexto NO toca la
/// sesión (RF-002): solo cambia qué pestañas se ven.
struct RootView: View {
    let services: AppServices
    @State private var phase: Phase = .launching
    @State private var selection: AppTab = .home
    @State private var homePath: [Route] = []
    @State private var accountPath: [Route] = []
    @Namespace private var zoomNamespace

    private enum Phase {
        case launching, welcome, main
    }

    var body: some View {
        Group {
            switch phase {
            case .launching:
                Theme.background.ignoresSafeArea()
            case .welcome:
                WelcomeView(model: services.welcome) { phase = .main }
            case .main:
                tabs
            }
        }
        .background(Theme.background)
        .task {
            await services.bootstrap()
            let seen = await services.onboarding.welcomeSeen()
            phase = seen ? .main : .welcome
        }
        .task { await services.watchCleanup() }
        .task { await services.watchContext() }
        .sheet(
            isPresented: Binding(
                get: { services.switcher.isSheetPresented },
                set: { services.switcher.isSheetPresented = $0 }
            )
        ) {
            ContextSheet(model: services.switcher)
        }
        .onChange(of: services.signals.welcomeResets) {
            services.welcome.prepareToShow()
            phase = .welcome
        }
        .onOpenURL(perform: open)
        .onChange(of: services.switcher.state.active) { _, active in
            selection = Self.home(of: active)
            homePath = []
            accountPath = []
        }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            ForEach(visibleTabs, id: \.self) { tab in
                content(for: tab)
                    .tabItem { Label(AppStrings.text(tab.titleKey), systemImage: tab.symbol) }
                    .tag(tab)
            }
        }
        .tint(Theme.primary)
        .environment(\.zoomNamespace, zoomNamespace)
    }

    private var visibleTabs: [AppTab] {
        [Self.home(of: services.switcher.state.active), .account]
    }

    @ViewBuilder private func content(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            NavigationStack(path: $homePath) {
                HomeView(
                    model: services.home,
                    switcher: services.switcher,
                    onOpenVenue: { id, key in homePath.append(.venue(id: id, sharedKey: key)) },
                    onOpenAccount: { selection = .account }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self, destination: destination)
            }
        case .owner:
            OwnerView(model: services.owner, switcher: services.switcher)
        case .admin:
            AdminView(switcher: services.switcher)
        case .account:
            NavigationStack(path: $accountPath) {
                AccountView(
                    model: services.account,
                    switcher: services.switcher,
                    showsDiagnostics: AppServices.showsDiagnostics,
                    onOpenDiagnostics: { accountPath.append(.diagnostics) }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self, destination: destination)
            }
        }
    }

    @ViewBuilder private func destination(_ route: Route) -> some View {
        switch route {
        case let .venue(id, key):
            VenueDetailScreen(venueID: id, sharedKey: key, services: services)
        case .diagnostics:
            DiagnosticsView(model: services.diagnostics, signedIn: services.account.isSignedIn) {
                accountPath.removeAll()
            }
        }
    }

    /// Universal links (ADR-IOS-0003). Los de venues abren el detalle en la pestaña de Inicio.
    private func open(_ url: URL) {
        guard let destination = UniversalLinkRouter.destination(for: url) else { return }
        switch destination {
        case .home:
            selection = Self.home(of: services.switcher.state.active)
        case let .venue(id):
            selection = .home
            homePath = [.venue(id: id, sharedKey: "link-\(id)")]
        case .account:
            selection = .account
        }
    }

    private static func home(of context: UserContext) -> AppTab {
        switch context {
        case .guest: .home
        case .owner: .owner
        case .admin: .admin
        }
    }
}

/// Crea el modelo del detalle una sola vez por pantalla: el cierre de `navigationDestination` se vuelve a evaluar con
/// cada cambio de la raíz y, sin `@State`, cada evaluación abriría un modelo nuevo y perdería el estado.
private struct VenueDetailScreen: View {
    @State private var model: DetailModel
    private let sharedKey: String

    init(venueID: String, sharedKey: String, services: AppServices) {
        _model = State(
            initialValue: DetailModel(
                venueID: venueID,
                repository: services.repository,
                saved: services.saved,
                consent: services.consent
            )
        )
        self.sharedKey = sharedKey
    }

    var body: some View {
        DetailView(model: model, sharedKey: sharedKey)
    }
}

extension AppTab {
    var titleKey: String {
        switch self {
        case .home: "tab.home"
        case .owner: "tab.owner"
        case .admin: "tab.admin"
        case .account: "tab.account"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .owner: "chart.bar"
        case .admin: "shield"
        case .account: "person"
        }
    }
}
