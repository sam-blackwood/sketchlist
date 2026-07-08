//
//  PlaylistTrack.swift
//  SketchList
//
//  Junction placing a track within a playlist, with a stable position and the
//  time it was added. Unlike a setlist, a track appears at most once per
//  playlist (see SYSTEM_DESIGN.md § Data Model, `PlaylistTracks`).
//

import Foundation
import SwiftData

/// A single track's membership in a playlist.
///
/// Maps to the `PlaylistTracks` table in SYSTEM_DESIGN.md. The schema uses a
/// composite primary key of `(playlist_id, track_id)` — enforcing at most one
/// entry per track — plus a unique `(playlist_id, position)` for stable ordering.
/// SwiftData can't express either compound constraint, so identity is a synthetic
/// UUID and both rules are enforced at the service layer.
@Model
final class PlaylistTrack {

    // MARK: Identity

    /// Synthetic identifier standing in for the schema's `(playlist_id, track_id)`
    /// composite key. Plain UUID, no `.unique` (see Track); the no-duplicate-track
    /// and unique-position rules live in the service layer.
    var id: UUID

    // MARK: Core Metadata

    /// 0-indexed slot providing a stable rendering order within the playlist.
    var position: Int

    // MARK: Timestamps

    /// When this track was added to the playlist. Unique to this junction — the
    /// setlist/transition joins don't track per-row add times.
    var addedAt: Date

    // MARK: Relationships

    /// The owning playlist. Inverse of `Playlist.playlistTracks`.
    var playlist: Playlist

    /// The track that belongs to this playlist.
    var track: Track

    // MARK: Init

    init(playlist: Playlist, track: Track, position: Int, addedAt: Date = .now) {
        self.id = UUID()
        self.playlist = playlist
        self.track = track
        self.position = position
        self.addedAt = addedAt
    }
}
