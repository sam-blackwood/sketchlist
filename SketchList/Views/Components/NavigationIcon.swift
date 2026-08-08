//
//  NavigationIcon.swift
//  SketchList
//
//  Marks for the sidebar destinations that are *not* entities — Home, Library,
//  and the three tools.
//
//  Separate from `EntityIcon` on purpose. `EntityKind` is a model type meaning
//  "the three things a user can create"; a navigation destination is not one of
//  those, and adding `.home` or `.tools` cases to it would put screen structure
//  inside the data model.
//
//  All stock SF Symbols. An earlier pass drew these by hand as axis-aligned bars
//  to match a then-custom Transition mark, and they were rejected — the drawn
//  ones were generic, and every concept here is one Apple already ships a
//  better-drawn version of. Transition has since gone stock too, so the app now
//  draws no custom marks at all (UI_DESIGN.md § Stock SF Symbols).
//

import SwiftUI

struct NavigationIcon: View {
    let destination: Destination

    /// Defaults to the point size of the text it sits beside, not a fixed
    /// number. SF Symbols align to cap height internally, so a symbol set at the
    /// label's own size lands correctly without hand-tuning — whereas pinning
    /// the icon while the type moves is what produced the earlier mismatch.
    var size: CGFloat = TextStyle.nav.size
    var weight: Font.Weight = .regular

    var body: some View {
        Image(systemName: destination.systemImage)
            .font(.system(size: size, weight: weight))
            .frame(width: size, height: size)
            .accessibilityHidden(true) // the row's label carries the meaning
    }
}

// MARK: - Destinations

extension NavigationIcon {
    /// Sidebar destinations with no entity behind them.
    ///
    /// The three entity lists — Setlists, Playlists, Transitions — are absent
    /// deliberately: they use `EntityIcon(kind:weight:.light)` so a Setlist wears
    /// the same mark in the sidebar that it wears on a creation button and in a
    /// row. One concept, one mark, everywhere.
    enum Destination: String, CaseIterable, Hashable {
        case home
        case library
        case mixGenerator
        case recommendations
        case setlistOrder

        var systemImage: String {
            switch self {
            case .home: "house"
            case .library: "books.vertical"

            // Chosen on silhouette as much as meaning. `music.note.list` was
            // the most literal — a generated tracklist is what this produces —
            // but it is three horizontal rows with a note, and Setlists,
            // Playlists and Transitions are already row-shaped marks two groups
            // above it; it would have read as a fourth collection rather than
            // as a tool. `sparkles` was distinct but promises an intelligence
            // this does not have: the generator is a scoring function over
            // Camelot compatibility, not a model.
            //
            // A bolt is distinct in shape, claims only "automatic", and picks up
            // an energy connotation that suits algorithms named Energy build and
            // Cool down. On probation — see UI_DESIGN.md § Still open.
            case .mixGenerator: "bolt"

            // A waveform under a magnifying glass. Chosen over the search and
            // idea glyphs because it says "look into the music" rather than
            // "search a table" — and the search is over musical properties,
            // Camelot key and BPM, not over text.
            case .recommendations: "waveform.badge.magnifyingglass"

            // Two points joined by an S-curve. Chosen over `arrow.up.arrow.down`
            // and the other sort glyphs because those say "reorder a table",
            // where this says *the arc of the set* — the shape a night takes
            // from opener to peak, which is what ordering a setlist is for.
            case .setlistOrder: "point.bottomleft.forward.to.point.topright.scurvepath"
            }
        }

        var title: String {
            switch self {
            case .home: "Home"
            case .library: "Library"
            case .mixGenerator: "Mix Generator"
            case .recommendations: "Recommendations"
            case .setlistOrder: "Setlist Order"
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

    /// A sidebar row backed by a stock symbol.
    private struct PreviewDestinationRow: View {
        let destination: NavigationIcon.Destination
        var isSelected = false

        var body: some View {
            HStack(spacing: Metrics.Space.regular) {
                NavigationIcon(destination: destination)
                Text(destination.title)
                Spacer(minLength: 0)
            }
            .textStyle(.nav)
            .foregroundStyle(isSelected ? Color.appAccent : .appInkDim)
            .frame(height: 32)
        }
    }

    /// A sidebar row backed by an entity mark, at the light weight.
    private struct PreviewEntityRow: View {
        let kind: EntityKind

        var body: some View {
            HStack(spacing: Metrics.Space.regular) {
                EntityIcon(kind: kind, size: TextStyle.nav.size, weight: .light)
                Text(kind.pluralName)
                Spacer(minLength: 0)
            }
            .textStyle(.nav)
            .foregroundStyle(.appInkDim)
            .frame(height: 32)
        }
    }

    private struct PreviewGroupHeader: View {
        let title: String

        var body: some View {
            Text(title)
                .textStyle(.label)
                .foregroundStyle(.appInkFaint)
                .padding(.top, Metrics.Space.roomy)
                .padding(.bottom, Metrics.Space.snug)
        }
    }

    #Preview("Settled marks — in place") {
        // Laid out as the sidebar rather than as a list of icons, because the
        // open question is whether Setlists, Playlists and Transitions still
        // read as siblings once the tool marks sit near them.
        VStack(alignment: .leading, spacing: 0) {
            PreviewDestinationRow(destination: .home, isSelected: true)
            PreviewDestinationRow(destination: .library)

            PreviewGroupHeader(title: "Collections")
            PreviewEntityRow(kind: .setlist)
            PreviewEntityRow(kind: .playlist)
            PreviewEntityRow(kind: .transition)

            PreviewGroupHeader(title: "Tools")
            PreviewDestinationRow(destination: .mixGenerator)
            PreviewDestinationRow(destination: .recommendations)
            PreviewDestinationRow(destination: .setlistOrder)
        }
        .padding(Metrics.Space.loose)
        .frame(width: 260, alignment: .leading)
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }

#endif
