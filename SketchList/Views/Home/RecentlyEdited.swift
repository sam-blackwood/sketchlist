//
//  RecentlyEdited.swift
//  SketchList
//
//  Home's "Jump back in" — the most recently edited setlists, playlists and
//  transitions in one list, newest first.
//
//  Three `@Query` properties rather than one, because SwiftData fetches a single
//  model type per query and these are three unrelated tables. There is no way to
//  ask for "the six most recent things across all of them", so the merge happens
//  here in memory. At personal-library scale that is nothing; if the library ever
//  grew enough to matter, the fix is a fetch limit per query, not a different
//  shape.
//
//  Named for what it queries rather than for the words on screen — the header
//  copy can change without the type becoming a lie.
//
//  The section is always present, including on a first launch when it has
//  nothing to show. An earlier pass hid it entirely; that made the empty screen
//  a different shape from the populated one, so the layout a new user learned
//  was not the layout they kept.
//

import SwiftData
import SwiftUI

struct RecentlyEdited: View {
    /// How many rows to show. UI_DESIGN.md § Screen: Home suggests six as a
    /// starting point — two rows of three, or six of one.
    var limit: Int = 6

    var onOpen: (LibraryEntity) -> Void = { _ in }

    @Query(sort: \Setlist.updatedAt, order: .reverse)
    private var setlists: [Setlist]

    @Query(sort: \Playlist.updatedAt, order: .reverse)
    private var playlists: [Playlist]

    @Query(sort: \Transition.updatedAt, order: .reverse)
    private var transitions: [Transition]

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if items.isEmpty {
                empty
            } else {
                ForEach(items) { item in
                    Button { onOpen(item) } label: {
                        EntityRow(id: item.id,
                                  name: item.name,
                                  kind: item.kind,
                                  trackCount: item.trackCount,
                                  updatedAt: item.updatedAt)
                    }
                    .buttonStyle(.plain)
                    .pointerStyle(.link)

                    Divider().overlay(Color.appRule)
                }
            }
        }
    }

    // MARK: Pieces

    /// The section header stays put whether or not there is anything under it —
    /// see the type header for why.
    ///
    /// Set at `.display` rather than `.label`. Previously the heading and the
    /// "Last edited" column label were both 9.5pt monospace in the same faint
    /// gray, which is the whole reason it read as weak: a section heading styled
    /// identically to the column label beside it *is* a column label. Raising it
    /// to 34pt states which of the two is the title (`Design/prototypes/
    /// section-header.html`, treatment 04).
    ///
    /// The two are baseline-aligned, not center-aligned. A 9.5pt label optically
    /// centered against 34pt capitals floats in the middle of empty space with
    /// nothing to relate to; on the baseline it shares a line with the heading.
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.Space.loose) {
            Text("Jump back in")
                .textStyle(.display)
                .foregroundStyle(.appInk)

            Spacer(minLength: 0)

            // Hidden when there are no rows: it labels a column that isn't there.
            if !items.isEmpty {
                Text("Last edited")
                    .textStyle(.label)
                    .foregroundStyle(.appInkFaint)
            }
        }
        .padding(.bottom, Metrics.Space.regular)
        .accessibilityAddTraits(.isHeader)
    }

    /// What sits where the rows would be on a first launch.
    ///
    /// Set at row size and centered in the space three rows would occupy, so the
    /// section reads as *a section holding one statement* rather than as a
    /// heading with nothing under it. The earlier version — 11pt monospace on
    /// the left edge between two rules — described an empty container, which is
    /// exactly the impression to avoid.
    ///
    /// Dim rather than faint: quieter than a real entity name, loud enough to be
    /// the answer to the heading above it instead of a footnote.
    private var empty: some View {
        Text("No recent work")
            .textStyle(.title)
            .foregroundStyle(.appInkDim)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.Row.entity * 3)
            .accessibilityLabel(Text(verbatim: "No recent work"))
    }

    /// The three lists merged and re-sorted. Each query is already sorted, so
    /// this could be a three-way merge — but at six items out of a personal
    /// library, sorting the concatenation is simpler and just as fast.
    private var items: [LibraryEntity] {
        let merged = setlists.map(LibraryEntity.setlist)
            + playlists.map(LibraryEntity.playlist)
            + transitions.map(LibraryEntity.transition)

        return Array(merged.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }
}

// MARK: - Preview

#Preview("Jump back in") {
    PreviewStore { container in
        ScrollView {
            RecentlyEdited()
                .padding(Metrics.Space.screen)
        }
        .frame(width: 900, height: 560)
        .background(Color.appBackground)
        .modelContainer(container)
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty library") {
    PreviewStore(seeded: false) { container in
        ScrollView {
            RecentlyEdited()
                .padding(Metrics.Space.screen)
        }
        .frame(width: 900, height: 240)
        .background(Color.appBackground)
        .modelContainer(container)
    }
    .preferredColorScheme(.dark)
}
