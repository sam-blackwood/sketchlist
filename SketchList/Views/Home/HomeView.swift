//
//  HomeView.swift
//  SketchList
//
//  The first screen. Emphasizes creation and continuation, not browsing —
//  the library lives in the sidebar and is deliberately not duplicated here
//  (UI_DESIGN.md § Screen: Home).
//
//  Three blocks: a summary of the library, the question and its three answers,
//  and what you were last working on.
//
//  All three are always present. Only the summary line can vanish — it has
//  nothing to say about an empty library. "Jump back in" stays even on a first
//  launch, showing "No recent work" where the rows would be, so the screen a new
//  user learns is the screen they keep (UI_DESIGN.md § Screen: Home).
//

import SwiftData
import SwiftUI

struct HomeView: View {
    /// Raised when a creation button is pressed. The naming flow and the jump
    /// into the new entity's editor belong to whatever presents this screen.
    var onCreate: (EntityKind) -> Void = { _ in }

    /// Raised when a recent item is clicked.
    var onOpen: (LibraryEntity) -> Void = { _ in }

    // Counts for the summary line. `@Query` fetches whole objects where a count
    // would do — fine at personal-library scale, and the alternative
    // (`fetchCount` in a ViewModel) gives up automatic refresh. Revisit only if
    // a library ever gets big enough to notice.
    @Query private var tracks: [Track]
    @Query private var setlists: [Setlist]
    @Query private var playlists: [Playlist]
    @Query private var transitions: [Transition]

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                Divider().overlay(Color.appRule)
                // Closer to the rule than the 32pt this used to be. The heading
                // below it is now 34pt rather than 9.5pt, so it needs less help
                // to register as the start of something.
                RecentlyEdited(onOpen: onOpen)
                    .padding(.top, Metrics.Space.loose)
            }
            .padding(.horizontal, Metrics.Space.screen)
            .padding(.top, Metrics.Space.screen)
            .padding(.bottom, Metrics.Space.screen)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
    }

    // MARK: Pieces

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let summary {
                Text(summary)
                    .textStyle(.label)
                    .foregroundStyle(.appHot)
                    .padding(.bottom, Metrics.Space.loose)
            }

            HeroHeadline()
                .padding(.bottom, Metrics.Space.section)

            HStack(spacing: Metrics.Space.seam) {
                CreationButton(label: "New", title: "Setlist", icon: .setlist) {
                    onCreate(.setlist)
                }
                CreationButton(label: "New", title: "Playlist", icon: .playlist) {
                    onCreate(.playlist)
                }
                CreationButton(label: "New", title: "Transition", icon: .transition) {
                    onCreate(.transition)
                }
            }
        }
        .padding(.bottom, Metrics.Space.screen)
    }

    /// "412 tracks · 9 setlists · 14 playlists · 37 transitions"
    ///
    /// Set in hot pink. This is the one line on Home where the app talks about
    /// the user's library rather than labelling a control, so it is where the
    /// app's voice belongs (UI_DESIGN.md § Color roles). It also earns the color
    /// structurally: nine words of 9.5pt monospace can carry a saturated hue
    /// without the screen tipping, where the 72pt headline could not.
    ///
    /// `nil` — and so no line at all — until the library holds *something*. Once
    /// it does, every count shows including the zeros: "1 track · 0 setlists"
    /// tells you the library has begun and what is still missing, whereas a line
    /// of four zeros on a brand-new install says nothing worth the space.
    ///
    /// No average BPM. A single figure across an entire library describes no
    /// track in it and answers no question anyone has.
    private var summary: String? {
        guard !tracks.isEmpty || !setlists.isEmpty
            || !playlists.isEmpty || !transitions.isEmpty
        else { return nil }

        return [count(tracks.count, "track"),
                count(setlists.count, "setlist"),
                count(playlists.count, "playlist"),
                count(transitions.count, "transition")]
            .joined(separator: " · ")
    }

    private func count(_ number: Int, _ noun: String) -> String {
        "\(number) \(noun)\(number == 1 ? "" : "s")"
    }
}

// MARK: - Preview

#Preview("Home") {
    PreviewStore { container in
        HomeView()
            .modelContainer(container)
            .frame(width: 1000, height: 820)
    }
    .preferredColorScheme(.dark)
}

#Preview("Home — first launch") {
    PreviewStore(seeded: false) { container in
        HomeView()
            .modelContainer(container)
            .frame(width: 1000, height: 820)
    }
    .preferredColorScheme(.dark)
}
