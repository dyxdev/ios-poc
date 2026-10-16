#if canImport(SwiftUI)
    import AppStrings
    import ContextUI
    import CoreModel
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Inicio (decisión de Andy, 2026-10-15): cabecera con marca, perfil y avatar; búsqueda; chips de categoría;
    /// carrusel de destacados con tira de fotos; y lista con corazón. Los eventos suben por cierres: la navegación se
    /// compone en la app.
    public struct HomeView: View {
        @Bindable private var model: HomeModel
        private let switcher: ContextSwitcherModel
        private let onOpenVenue: (String, String) -> Void
        private let onOpenAccount: () -> Void

        public init(
            model: HomeModel,
            switcher: ContextSwitcherModel,
            onOpenVenue: @escaping (String, String) -> Void,
            onOpenAccount: @escaping () -> Void
        ) {
            self.model = model
            self.switcher = switcher
            self.onOpenVenue = onOpenVenue
            self.onOpenAccount = onOpenAccount
        }

        public var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    SearchField(
                        text: $model.query,
                        placeholder: AppStrings.text("home.search.placeholder"),
                        clearLabel: AppStrings.text("home.search.clear")
                    )
                    .padding(.horizontal, Spacing.lg)
                    categories
                    content
                }
                .padding(.vertical, Spacing.lg)
            }
            .background(Theme.background)
            .scrollDismissesKeyboard(.immediately)
            .task { await model.load() }
            .task { await model.observeSaved() }
            .onChange(of: model.isLoading) { _, loading in
                if !loading {
                    // Tras la primera carga la entrada escalonada ya no se repite.
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        model.introPlayed()
                    }
                }
            }
        }

        private var header: some View {
            HStack {
                VenueNexaWordmark()
                Spacer()
                ContextLabel(model: switcher)
                Button {
                    // Con más de un perfil, el avatar abre la hoja de perfiles; si no, lleva a la cuenta.
                    if switcher.state.canSwitch { switcher.openSheet() } else { onOpenAccount() }
                } label: {
                    Image(systemName: "person")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.text)
                        .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                }
                .accessibilityLabel(
                    AppStrings.text(switcher.state.canSwitch ? "context.sheet.title" : "home.account")
                )
            }
            .padding(.horizontal, Spacing.lg)
        }

        private var categories: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    CategoryChip(
                        title: AppStrings.text("home.category.all"),
                        isSelected: model.category == nil
                    ) { model.toggleCategory(nil) }
                    ForEach(VenueCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: AppStrings.text("category.\(category.rawValue)"),
                            isSelected: model.category == category
                        ) { model.toggleCategory(category) }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }

        @ViewBuilder private var content: some View {
            if model.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        VenueSkeleton(featured: true)
                        VenueSkeleton(featured: true)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                ForEach(0..<3, id: \.self) { _ in
                    VenueSkeleton(featured: false).padding(.horizontal, Spacing.lg)
                }
            } else {
                if !model.isFiltering, !model.featured.isEmpty {
                    featuredSection
                }
                SectionHeader(AppStrings.text(model.isFiltering ? "home.results" : "home.all"))
                    .padding(.horizontal, Spacing.lg)
                if model.results.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, venue in
                        VenueListCard(
                            venue: venue,
                            isSaved: model.savedIDs.contains(venue.id),
                            onOpen: { onOpenVenue(venue.id, $0) },
                            onToggleSaved: { model.toggleSaved(venue.id) }
                        )
                        .padding(.horizontal, Spacing.lg)
                        .staggeredEntrance(index: index + 2, play: model.playIntro)
                    }
                }
            }
        }

        private var featuredSection: some View {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(AppStrings.text("home.featured")).padding(.horizontal, Spacing.lg)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        ForEach(Array(model.featured.enumerated()), id: \.element.id) { index, venue in
                            FeaturedVenueCard(
                                venue: venue,
                                isSaved: model.savedIDs.contains(venue.id),
                                onOpen: { onOpenVenue(venue.id, $0) },
                                onToggleSaved: { model.toggleSaved(venue.id) }
                            )
                            .staggeredEntrance(index: index, play: model.playIntro)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
        }

        private var emptyState: some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(verbatim: AppStrings.text("home.empty.title")).font(.outfit(.headline)).foregroundStyle(Theme.text)
                Text(verbatim: AppStrings.text("home.empty.hint")).font(.outfit(.body)).foregroundStyle(Theme.textMuted)
                Button(AppStrings.text("home.empty.clear")) { model.clearFilters() }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 220)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
#endif
