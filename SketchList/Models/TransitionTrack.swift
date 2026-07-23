//
//  TransitionTrack.swift
//  SketchList
//
//  Junction placing a track at a specific position within a stored transition
//  (see SYSTEM_DESIGN.md § Data Model, `TransitionTracks`).
//

import Foundation
import SwiftData

/// A single track's placement within a transition.
///
/// Maps to the `TransitionTracks` table in SYSTEM_DESIGN.md. The schema keys
/// ordering on a unique `(transition_id, position)` constraint; SwiftData can't
/// express that compound constraint, so identity is a synthetic UUID and position
/// uniqueness is maintained at the service layer. Single-track transitions are
/// valid (one row at position 0) and duplicate tracks within a transition are
/// intentionally allowed.
@Model
final class TransitionTrack: Positioned {
    // MARK: Identity

    /// Synthetic identifier. Plain UUID, no `.unique` (see Track). The schema's
    /// `(transition_id, position)` uniqueness is enforced in the service layer.
    var id: UUID

    // MARK: Core Metadata

    /// 0-indexed slot in the transition; position 0 is the first track.
    var position: Int

    // MARK: Relationships

    // Optional (required in practice): during a cascade delete SwiftData invalidates
    // the deleted child's relationships, and reading a non-optional to-one afterward
    // logs "read after invalidation" and can crash an observing SwiftUI view. Optional
    // lets those post-deletion reads resolve to nil. The schema's NOT NULL intent is
    // enforced by the init, which requires both endpoints.

    /// The owning transition. Inverse of `Transition.transitionTracks`.
    var transition: Transition?

    /// The track placed at this position.
    var track: Track?

    // MARK: Init

    init(transition: Transition, track: Track, position: Int) {
        id = UUID()
        self.transition = transition
        self.track = track
        self.position = position
    }
}
