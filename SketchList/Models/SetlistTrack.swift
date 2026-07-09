//
//  SetlistTrack.swift
//  SketchList
//
//  Junction placing a track at a specific position within a setlist. This is
//  what makes a setlist an *ordered* collection (see SYSTEM_DESIGN.md § Data Model,
//  `SetlistTracks`).
//

import Foundation
import SwiftData

/// A single track's placement within a setlist.
///
/// Maps to the `SetlistTracks` table in SYSTEM_DESIGN.md. The schema keys ordering
/// on a unique `(setlist_id, position)` constraint; SwiftData can't express that
/// compound constraint, so identity is a synthetic UUID and position uniqueness is
/// maintained at the service layer during reordering. Duplicate tracks within one
/// setlist are intentionally allowed (e.g. an intro/outro reprise).
@Model
final class SetlistTrack {

    // MARK: Identity

    /// Synthetic identifier. Plain UUID, no `.unique` (see Track). The schema's
    /// `(setlist_id, position)` uniqueness is enforced in the service layer.
    var id: UUID

    // MARK: Core Metadata

    /// 0-indexed slot in the setlist; position 0 is the first track.
    var position: Int

    // MARK: Relationships

    // Optional (required in practice): during a cascade delete SwiftData invalidates
    // the deleted child's relationships, and reading a non-optional to-one afterward
    // logs "read after invalidation" and can crash an observing SwiftUI view. Optional
    // lets those post-deletion reads resolve to nil. The schema's NOT NULL intent is
    // enforced by the init, which requires both endpoints.

    /// The owning setlist. Inverse of `Setlist.setlistTracks`.
    var setlist: Setlist?

    /// The track placed at this position.
    var track: Track?

    // MARK: Init

    init(setlist: Setlist, track: Track, position: Int) {
        self.id = UUID()
        self.setlist = setlist
        self.track = track
        self.position = position
    }
}
