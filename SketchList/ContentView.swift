//
//  ContentView.swift
//  SketchList
//
//  The app shell — the left panel beside whatever it is pointing at
//  (UI_DESIGN.md § Overall Layout).
//
//  `NavigationSplitView` rather than a hand-rolled `HStack` so the panel gets
//  the platform behavior for free: the ⌘0 toggle, the toolbar control, drag to
//  resize, and the system's own hide/show animation. On macOS this hides the
//  sidebar outright rather than collapsing it to an icon rail, which is the
//  behavior we want — a rail would make marks mandatory and rule out the quiet
//  mono direction entirely.
//
//  Only Home is real. Every other destination is a `PlaceholderScreen` until its
//  screen is built.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarDestination = .home

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: Metrics.Pane.sidebarMin,
                                                ideal: Metrics.Pane.sidebarIdeal,
                                                max: Metrics.Pane.sidebarMax)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
        }
        .navigationTitle(selection.title)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .home:
            HomeView(onCreate: create, onOpen: open)
        default:
            PlaceholderScreen(destination: selection)
        }
    }

    // MARK: Actions

    /// Raised by Home's creation buttons.
    ///
    /// Unimplemented: the real flow prompts for a name, enforces the
    /// unique-within-type constraint, then opens the new entity's editor
    /// (UI_DESIGN.md § Screen: Home). None of those exist, so for now this moves
    /// the selection to the matching list, which at least proves the plumbing
    /// without pretending the flow is there.
    private func create(_ kind: EntityKind) {
        selection = destination(for: kind)
    }

    /// Raised when a recent item is clicked. Should open that entity's editor;
    /// there are no editors yet, so it lands on the list its kind belongs to.
    private func open(_ entity: LibraryEntity) {
        selection = destination(for: entity.kind)
    }

    private func destination(for kind: EntityKind) -> SidebarDestination {
        switch kind {
        case .setlist: .setlists
        case .playlist: .playlists
        case .transition: .transitions
        }
    }
}

// MARK: - Preview

#Preview("App shell") {
    PreviewStore { container in
        ContentView()
            .modelContainer(container)
            .frame(width: 1100, height: 780)
    }
    .preferredColorScheme(.dark)
}
