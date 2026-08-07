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
//  to match the custom Transition mark, and they were rejected — the drawn ones
//  were generic, and every concept here (a house, a shelf, a gear, a numbered
//  list) is one Apple already ships a better-drawn version of. Custom marks earn
//  their place only where no stock symbol carries the meaning, which in this app
//  is Transition alone (UI_DESIGN.md § Stock SF Symbols).
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

            // A mixer channel strip, not a gear. `gearshape` means "settings" in
            // essentially every application ever shipped, and this tool is not
            // settings — it builds a mix, and faders say mixing to any DJ. The
            // app has no audio, but on a *tool* the glyph reads as intent, what
            // this makes, rather than as a transport control. That distinction
            // is why it belongs here and not on the Transition entity.
            case .mixGenerator: "slider.vertical.3"

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

    #Preview("Family check — mixer strip against the trio") {
        // The three entity marks beside the tool that now wears faders. If the
        // channel strip pulls the eye away from the Collections group, or if
        // Transition starts looking like a tool rather than a thing you own,
        // that is the argument for leaving `gearshape` on Mix Generator.
        VStack(alignment: .leading, spacing: Metrics.Space.loose) {
            Text("Entity marks — the trio")
                .textStyle(.label).foregroundStyle(.appInkFaint)
            HStack(spacing: Metrics.Space.section) {
                ForEach([EntityKind.setlist, .playlist, .transition], id: \.self) { kind in
                    EntityIcon(kind: kind, size: 40, weight: .light)
                }
            }
            .foregroundStyle(.appInk)

            Text("Tool marks")
                .textStyle(.label).foregroundStyle(.appInkFaint)
            HStack(spacing: Metrics.Space.section) {
                NavigationIcon(destination: .mixGenerator, size: 40)
                NavigationIcon(destination: .recommendations, size: 40)
                NavigationIcon(destination: .setlistOrder, size: 40)
            }
            .foregroundStyle(.appInk)
        }
        .padding(Metrics.Space.screen)
        .frame(width: 420, alignment: .leading)
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }

#endif
