//
//  TrackArtist.swift
//  SketchList
//
//  Junction between Tracks and Artists — the many-to-many link that lets a
//  track credit multiple artists and an artist appear on multiple tracks
//  (see SYSTEM_DESIGN.md § Data Model, `TrackArtists`).
//

import Foundation
import SwiftData

/// A single track-to-artist credit.
///
/// Maps to the `TrackArtists` junction table in SYSTEM_DESIGN.md. The schema
/// defines a composite primary key of `(track_id, artist_id)`; SwiftData can't
/// express composite keys, so identity is a synthetic UUID and the "one credit
/// per (track, artist)" rule is enforced at the service layer on insert.
@Model
final class TrackArtist {

    // MARK: Identity

    /// Synthetic identifier standing in for the schema's `(track_id, artist_id)`
    /// composite key, which SwiftData doesn't support. Plain UUID, no `.unique`
    /// (see Track); the one-credit-per-pair rule is enforced in the service layer.
    var id: UUID

    // MARK: Relationships

    // Optional (required in practice): during a cascade delete SwiftData invalidates
    // the deleted child's relationships, and reading a non-optional to-one afterward
    // logs "read after invalidation" and can crash an observing SwiftUI view. Optional
    // lets those post-deletion reads resolve to nil. The schema's NOT NULL intent is
    // enforced by the init, which requires both endpoints.

    /// The track side of the credit. Inverse of `Track.trackArtists`.
    var track: Track?

    /// The artist side of the credit. Inverse of `Artist.trackArtists`.
    var artist: Artist?

    // MARK: Init

    init(track: Track, artist: Artist) {
        self.id = UUID()
        self.track = track
        self.artist = artist
    }
}
