//
//  Setlist.swift
//  SketchList
//
//  An ordered, named collection of tracks the user intends to mix in a set.
//  Ordering is meaningful and user-controlled via drag-and-drop
//  (see SYSTEM_DESIGN.md § Data Model and UI_DESIGN.md § Screen: Setlist View).
//

import Foundation
import SwiftData

/// A single setlist in the user's library.
///
/// Maps to the `Setlists` table in SYSTEM_DESIGN.md. The track order lives on the
/// `SetlistTracks` join rows (via their `position`), not here — this entity holds
/// only the setlist's identity and descriptive metadata.
@Model
final class Setlist {
    // MARK: Identity

    /// Domain identifier. Plain UUID, no `.unique` constraint — see Track for the
    /// rationale. SwiftData tracks object identity internally regardless.
    var id: UUID

    // MARK: Core metadata

    /// Display name. Required, and unique within setlists — the "no duplicate
    /// names within a type" rule from SYSTEM_DESIGN.md, enforced at the service
    /// layer (names may still be reused across setlists / playlists / transitions).
    var name: String

    /// Optional free-text description. Named `descriptionText` to avoid clashing
    /// with `CustomStringConvertible.description`. Describes the setlist's
    /// *purpose* (e.g. "warehouse closing set") — distinct from `notes` below.
    var descriptionText: String?

    /// Optional working notes: longer, more granular annotations than the
    /// description, such as cue points or reminders (e.g. "start transition at
    /// 0:48"). Mirrors the `notes` field on Track.
    var notes: String?

    // MARK: Artwork

    /// Filename of this setlist's cover art within
    /// `~/Library/Application Support/SketchList/Covers/`, or `nil` for the
    /// generated default (UI_DESIGN.md § Custom Cover Art).
    ///
    /// A filename rather than image data: keeping binaries out of the store keeps
    /// it small and keeps fetches cheap. A *filename* rather than a full path so
    /// the library survives the app-support directory moving between machines.
    ///
    /// Deliberately a plain filename rather than a description of how the art was
    /// made. Art built with the in-app creator is rendered to a file and stored
    /// the same way as an upload, so editing it means making a new one — matching
    /// how Spotify's playlist cover tool behaves. That trade buys one nullable
    /// column instead of a variant type.
    var artworkFilename: String?

    // MARK: Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: Relationships

    /// The ordered join rows placing tracks in this setlist. Deleting a Setlist
    /// cascades to its join rows (not to the Tracks themselves).
    @Relationship(deleteRule: .cascade, inverse: \SetlistTrack.setlist)
    var setlistTracks: [SetlistTrack] = []

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
