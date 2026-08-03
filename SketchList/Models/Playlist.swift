//
//  Playlist.swift
//  SketchList
//
//  A named collection of tracks grouped by vibe, feel, or genre — distinct from
//  a Setlist, which is an intended mix order. A playlist is more of a bucket
//  (see SYSTEM_DESIGN.md § Data Model and the Playlists user story).
//

import Foundation
import SwiftData

/// A single playlist in the user's library.
///
/// Maps to the `Playlists` table in SYSTEM_DESIGN.md. Membership and ordering live
/// on the `PlaylistTracks` join rows; this entity holds only the playlist's
/// identity and descriptive metadata.
@Model
final class Playlist {
    // MARK: Identity

    /// Domain identifier. Plain UUID, no `.unique` constraint — see Track for the
    /// rationale. SwiftData tracks object identity internally regardless.
    var id: UUID

    // MARK: Core metadata

    /// Display name. Required, and unique within playlists — the "no duplicate
    /// names within a type" rule from SYSTEM_DESIGN.md, enforced at the service
    /// layer (names may still be reused across setlists / playlists / transitions).
    var name: String

    /// Optional free-text description. Named `descriptionText` to avoid clashing
    /// with `CustomStringConvertible.description`. Describes the playlist's
    /// *purpose* (e.g. "late-night deep house") — distinct from `notes` below.
    var descriptionText: String?

    /// Optional working notes: longer, more granular annotations than the
    /// description, such as cue points or reminders (e.g. "start transition at
    /// 0:48"). Mirrors the `notes` field on Track.
    var notes: String?

    // MARK: Artwork

    /// Filename of this playlist's cover art within
    /// `~/Library/Application Support/SketchList/Covers/`, or `nil` for the
    /// generated default (UI_DESIGN.md § Custom Cover Art).
    ///
    /// See `Setlist.artworkFilename` for the reasoning behind storing a filename
    /// rather than image data or a description of how the art was made.
    var artworkFilename: String?

    // MARK: Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: Relationships

    /// The join rows placing tracks in this playlist. Deleting a Playlist cascades
    /// to its join rows (not to the Tracks themselves).
    @Relationship(deleteRule: .cascade, inverse: \PlaylistTrack.playlist)
    var playlistTracks: [PlaylistTrack] = []

    // MARK: Init

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String? = nil,
        notes: String? = nil,
        artworkFilename: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.notes = notes
        self.artworkFilename = artworkFilename
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
