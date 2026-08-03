//
//  EntityKind.swift
//  SketchList
//
//  Which of the three container types something is: Setlist, Playlist, or
//  Transition.
//
//  Lives here rather than nested inside a view because both layers need it —
//  `EntityIcon` and `EntityRow` to render, and Home's recents merge to label a
//  mixed list. Vocabulary the data layer uses shouldn't be owned by a view.
//
//  "Entity" over the more natural "collection" or "list": both of those are
//  taken by Swift's `Collection` protocol and SwiftUI's `List`, and the constant
//  disambiguation isn't worth the nicer word.
//

import Foundation

enum EntityKind: String, CaseIterable, Identifiable, Hashable {
    case setlist = "Setlist"
    case playlist = "Playlist"
    case transition = "Transition"

    var id: String { rawValue }

    /// Singular, as shown in a row's type column.
    var displayName: String { rawValue }

    /// Plural, as shown in sidebar sections and screen titles.
    var pluralName: String { rawValue + "s" }
}
