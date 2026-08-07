//
//  SidebarDestination.swift
//  SketchList
//
//  Everything the left panel can navigate to (UI_DESIGN.md § Left Panel).
//
//  Deliberately flat rather than an enum with an associated `EntityKind`. A flat
//  set of cases is `Hashable` and `CaseIterable` for free, which is what
//  `NavigationSplitView` selection and `Table`-style iteration both want; the
//  entity relationship is recovered through `entityKind` where it's needed.
//
//  This type owns *where you can go*, not how a row looks. It maps to the two
//  icon components rather than holding symbol names itself, so a mark changes in
//  one place.
//

import Foundation

enum SidebarDestination: String, Hashable, CaseIterable, Identifiable {
    case home
    case library

    case setlists
    case playlists
    case transitions

    case mixGenerator
    case recommendations
    case setlistOrder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .setlists: EntityKind.setlist.pluralName
        case .playlists: EntityKind.playlist.pluralName
        case .transitions: EntityKind.transition.pluralName
        case .mixGenerator: "Mix Generator"
        case .recommendations: "Recommendations"
        case .setlistOrder: "Setlist Order"
        }
    }

    /// Non-nil for the three destinations that list an entity type. Those rows
    /// wear `EntityIcon`, so a Setlist carries the same mark in the sidebar that
    /// it carries on a creation button and in a row.
    var entityKind: EntityKind? {
        switch self {
        case .setlists: .setlist
        case .playlists: .playlist
        case .transitions: .transition
        default: nil
        }
    }

    /// Non-nil for everything else — the destinations backed by a stock symbol.
    /// Exactly the inverse of `entityKind`; one of the two is always set.
    var navIcon: NavigationIcon.Destination? {
        switch self {
        case .home: .home
        case .library: .library
        case .mixGenerator: .mixGenerator
        case .recommendations: .recommendations
        case .setlistOrder: .setlistOrder
        default: nil
        }
    }
}

// MARK: - Grouping

extension SidebarDestination {
    /// The sidebar's sections, in order.
    ///
    /// A section with a `nil` title renders without a header — the top group is
    /// just Home and Library, which need no label to explain them.
    struct Section: Identifiable {
        let title: String?
        let destinations: [SidebarDestination]

        var id: String { title ?? "root" }
    }

    /// All three tools ship, including the two whose screens are post-v1 in
    /// SYSTEM_DESIGN.md. Keeping them visible means the sidebar never changes
    /// shape as features land.
    static let sections: [Section] = [
        Section(title: nil, destinations: [.home, .library]),
        Section(title: "Collections", destinations: [.setlists, .playlists, .transitions]),
        Section(title: "Tools", destinations: [.mixGenerator, .recommendations, .setlistOrder]),
    ]
}
