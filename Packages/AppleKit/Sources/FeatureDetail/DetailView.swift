#if canImport(SwiftUI) && canImport(AVKit)
    import AVKit
    import AppStrings
    import CoreModel
    import CoreVenues
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    /// Detalle de un venue: galería con contador, cabecera, tres cifras que cuentan, vídeo tour con AVPlayer y barra de
    /// reserva. La foto de la tarjeta «viaja» hasta aquí (transición de zoom, iOS 18; con iOS 17 es la normal).
    public struct DetailView: View {
        private let model: DetailModel
        private let sharedKey: String
        @State private var tour = TourPlayerModel()
        @Environment(\.locale) private var locale
        @Environment(\.displayScale) private var displayScale
        @Environment(\.scenePhase) private var scenePhase
        @Environment(\.dismiss) private var dismiss

        public init(model: DetailModel, sharedKey: String) {
            self.model = model
            self.sharedKey = sharedKey
        }

        public var body: some View {
            Group {
                switch model.phase {
                case .loading:
                    ShimmerBox().aspectRatio(Layout.photoAspect, contentMode: .fit).padding(Spacing.lg)
                case .notFound:
                    notFound
                case let .content(venue):
                    content(venue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .tabBar)
            .zoomDestination(id: sharedKey)
            .task { await model.load() }
            .task { await model.observeSaved() }
            .task { await model.observeConsent() }
            .onChange(of: scenePhase) { _, phase in
                // Al pasar a segundo plano el vídeo se pausa (si no, seguiría sonando sin pantalla).
                if phase != .active { tour.pause() }
            }
            .onDisappear { tour.stop() }
            .alert(AppStrings.text("detail.reserve.soon"), isPresented: showNotice) {
                Button(AppStrings.text("detail.ok"), role: .cancel) {}
            }
        }

        private var showNotice: Binding<Bool> {
            Binding(get: { model.showsReserveNotice }, set: { model.showsReserveNotice = $0 })
        }

        private func content(_ venue: Venue) -> some View {
            let text = VenueText(venue: venue, locale: locale)
            return VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        gallery(venue, text: text)
                        header(venue, text: text)
                        figures(venue)
                        if let url = model.tourURL(for: venue) {
                            tourSection(venue, url: url)
                        }
                    }
                    .padding(Spacing.lg)
                }
                reserveBar(venue, text: text)
            }
        }

        private func gallery(_ venue: Venue, text: VenueText) -> some View {
            ZStack(alignment: .top) {
                GalleryPager(photos: venue.photos, description: text.photoDescription, scale: displayScale)
                HStack {
                    circleButton(system: "chevron.left", label: AppStrings.text("detail.back")) { dismiss() }
                    Spacer()
                    SaveButton(
                        isSaved: model.isSaved,
                        label: model.isSaved ? text.unsaveLabel : text.saveLabel,
                        action: { model.toggleSaved() }
                    )
                    .background(Theme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Radius.standard))
                }
                .padding(Spacing.sm)
            }
            .aspectRatio(Layout.photoAspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.standard))
            .zoomSource(id: sharedKey)
        }

        private func circleButton(system: String, label: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Image(systemName: system)
                    .foregroundStyle(Theme.text)
                    .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                    .background(Theme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Radius.standard))
            }
            .accessibilityLabel(label)
        }

        private func header(_ venue: Venue, text: VenueText) -> some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(verbatim: venue.name).font(.outfit(.title)).foregroundStyle(Theme.text)
                Text(verbatim: venue.city).font(.outfit(.body)).foregroundStyle(Theme.textMuted)
                HStack(spacing: Spacing.lg) {
                    RatingLabel(text: text.rating)
                    AvailabilityLabel(text: text.availability, isAvailable: venue.isAvailable)
                }
            }
        }

        private func figures(_ venue: Venue) -> some View {
            HStack(spacing: Spacing.md) {
                FigureCard(label: AppStrings.text("detail.figure.capacity")) {
                    CountingText(target: venue.capacity)
                }
                FigureCard(label: AppStrings.text("detail.figure.price")) {
                    CountingText(target: venue.pricePerDay) { Formatters.price($0, locale: locale) }
                }
                FigureCard(label: AppStrings.text("detail.figure.reviews")) {
                    CountingText(target: venue.reviewCount)
                }
            }
        }

        private func tourSection(_ venue: Venue, url: URL) -> some View {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(AppStrings.text("detail.tour.title"))
                ZStack {
                    if let player = tour.player {
                        VideoPlayer(player: player)
                    } else {
                        poster(venue, url: url)
                    }
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Radius.standard))
                // La analítica solo se enseña para que se vea la puerta del consentimiento; el vídeo suena igual.
                Text(verbatim: AppStrings.text(model.analyticsConsent ? "detail.analytics.on" : "detail.analytics.off"))
                    .font(.outfit(.caption))
                    .foregroundStyle(Theme.textMuted)
            }
        }

        private func poster(_ venue: Venue, url: URL) -> some View {
            Button {
                tour.start(url: url)
            } label: {
                ZStack {
                    VenueImage(
                        url: RenditionURL.make(for: venue.photos.last ?? venue.cover, points: 340, scale: displayScale),
                        accessibilityText: nil
                    )
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.primary)
                        .frame(width: 56, height: 56)
                        .background(Theme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Radius.standard))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.text("detail.tour.play"))
        }

        private func reserveBar(_ venue: Venue, text: VenueText) -> some View {
            HStack(spacing: Spacing.lg) {
                Text(verbatim: text.price).font(.outfit(.headline)).foregroundStyle(Theme.success)
                Spacer()
                Button(AppStrings.text(venue.isAvailable ? "detail.reserve" : "venue.unavailable")) {
                    model.reserveTapped()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!venue.isAvailable)
                .frame(maxWidth: 180)
            }
            .padding(Spacing.lg)
            .background(Theme.surface)
            .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 1) }
        }

        private var notFound: some View {
            VStack(spacing: Spacing.lg) {
                Text(verbatim: AppStrings.text("detail.notfound")).font(.outfit(.headline)).foregroundStyle(Theme.text)
                Button(AppStrings.text("detail.back")) { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 220)
            }
            .padding(Spacing.xl)
        }
    }

    /// Galería a ancho completo con el contador «1 / 3». La primera foto es la que viaja desde la tarjeta.
    struct GalleryPager: View {
        let photos: [URL]
        let description: String
        let scale: Double
        @State private var page = 0

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $page) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                        VenueImage(
                            url: RenditionURL.make(for: url, points: 360, scale: scale),
                            accessibilityText: description
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                if photos.count > 1 {
                    Text(verbatim: AppStrings.format("detail.photo.counter", page + 1, photos.count))
                        .font(.outfit(.caption))
                        .foregroundStyle(Theme.surface)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Theme.text.opacity(0.72), in: RoundedRectangle(cornerRadius: 4))
                        .padding(Spacing.sm)
                }
            }
        }
    }

    struct VenueText {
        let venue: Venue
        let locale: Locale

        var rating: String { Formatters.rating(venue.rating, reviewCount: venue.reviewCount, locale: locale) }
        var price: String {
            AppStrings.format("venue.price.perday", Formatters.price(venue.pricePerDay, locale: locale))
        }
        var availability: String { AppStrings.text(venue.isAvailable ? "venue.available" : "venue.unavailable") }
        var photoDescription: String { AppStrings.format("venue.photo", venue.name) }
        var saveLabel: String { AppStrings.format("venue.save", venue.name) }
        var unsaveLabel: String { AppStrings.format("venue.unsave", venue.name) }
    }
#endif
