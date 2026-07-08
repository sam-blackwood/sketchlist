//
//  Transition.swift
//  SketchList
//
//  A small, named, ordered collection of tracks capturing a favorite move the
//  user wants to remember and reuse across mixes. Can be created from scratch or
//  lifted from a selection within a setlist (see SYSTEM_DESIGN.md § Data Model and
//  UI_DESIGN.md § Screen: Setlist View — "Create Transition").
//

import Foundation
import SwiftData

/// A single stored transition in the user's library.
///
/// Maps to the `Transitions` table in SYSTEM_DESIGN.md. Its ordered tracks live on
/// the `TransitionTracks` join rows; this entity holds only the transition's
/// identity and descriptive metadata. A transition may be as short as one track.
@Model
final class Transition {

    // MARK: Identity

    /// Domain identifier. Plain UUID, no `.unique` constraint — see Track for the
    /// rationale. SwiftData tracks object identity internally regardless.
    var id: UUID

    // MARK: Core metadata

    /// Display name. Required, and unique within transitions — the "no duplicate
    /// names within a type" rule from SYSTEM_DESIGN.md, enforced at the service
    /// layer (names may still be reused across setlists / playlists / transitions).
    var name: String

    /// Optional free-text description. Named `descriptionText` to avoid clashing
    /// with `CustomStringConvertible.description`. Describes the transition's
    /// *purpose* (e.g. "energy lift into peak") — distinct from `notes` below.
    var descriptionText: String?

    /// Optional working notes: longer, more granular annotations than the
    /// description, such as cue points or reminders (e.g. "start transition at
    /// 0:48"). Mirrors the `notes` field on Track.
    var notes: String?

    // MARK: Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: Relationships

    /// The ordered join rows placing tracks in this transition. Deleting a
    /// Transition cascades to its join rows (not to the Tracks themselves).
    @Relationship(deleteRule: .cascade, inverse: \TransitionTrack.transition)
    var transitionTracks: [TransitionTrack] = []

    // MARK: Init

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
