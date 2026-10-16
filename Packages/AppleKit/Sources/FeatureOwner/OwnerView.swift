#if canImport(SwiftUI)
    import AppStrings
    import ContextUI
    import CoreModel
    import CoreVenues
    import DesignSystemUI
    import DesignTokens
    import SwiftUI

    public struct OwnerView: View {
        private let model: OwnerModel
        private let switcher: ContextSwitcherModel
        @Environment(\.locale) private var locale
        @Environment(\.displayScale) private var displayScale

        public init(model: OwnerModel, switcher: ContextSwitcherModel) {
            self.model = model
            self.switcher = switcher
        }

        public var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack {
                        Text(verbatim: AppStrings.text("owner.title"))
                            .font(.outfit(.title))
                            .foregroundStyle(Theme.text)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        ContextLabel(model: switcher)
                    }
                    Text(verbatim: AppStrings.text("owner.sample.note"))
                        .font(.outfit(.caption))
                        .foregroundStyle(Theme.textMuted)
                    figures
                    SectionHeader(AppStrings.text("owner.venues.title"))
                    if let venues = model.venues {
                        ForEach(Array(venues.enumerated()), id: \.element.id) { index, venue in
                            OwnerVenueRow(venue: venue, scale: displayScale)
                                .staggeredEntrance(index: index, play: true)
                        }
                    } else {
                        ShimmerBox()
                            .frame(height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.standard))
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Theme.background)
            .task { await model.load() }
        }

        private var figures: some View {
            HStack(spacing: Spacing.md) {
                FigureCard(label: AppStrings.text("owner.figure.pending")) {
                    CountingText(target: OwnerModel.samplePendingBookings)
                }
                FigureCard(label: AppStrings.text("owner.figure.income")) {
                    CountingText(target: OwnerModel.sampleMonthIncome) { Formatters.price($0, locale: locale) }
                }
                FigureCard(label: AppStrings.text("owner.figure.venues")) {
                    CountingText(target: model.venues?.count ?? 0)
                }
            }
        }
    }

    private struct OwnerVenueRow: View {
        let venue: Venue
        let scale: Double

        var body: some View {
            HStack(spacing: Spacing.md) {
                VenueImage(
                    url: RenditionURL.make(for: venue.cover, points: 72, scale: scale),
                    accessibilityText: AppStrings.format("venue.photo", venue.name)
                )
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Radius.standard))
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: venue.name).font(.outfit(.headline)).foregroundStyle(Theme.text)
                    Text(verbatim: venue.city).font(.outfit(.caption)).foregroundStyle(Theme.textMuted)
                    AvailabilityLabel(
                        text: AppStrings.text(venue.isAvailable ? "venue.available" : "venue.unavailable"),
                        isAvailable: venue.isAvailable
                    )
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }
#endif
