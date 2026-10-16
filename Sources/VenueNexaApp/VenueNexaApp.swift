import DesignSystemUI
import SwiftUI

@main
struct VenueNexaApp: App {
    @State private var services: AppServices

    init() {
        FontRegistration.registerOutfit()
        _services = State(initialValue: AppServices())
    }

    var body: some Scene {
        WindowGroup {
            RootView(services: services)
        }
    }
}
