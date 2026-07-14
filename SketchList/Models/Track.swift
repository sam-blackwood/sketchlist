//
//  Track.swift
//  SketchList
//
//  The core library entity. A Track is metadata only — SketchList never
//  stores or plays audio (see SYSTEM_DESIGN.md § Metadata-only).
//

import Foundation
import SwiftData

/// A single track in the user's library.
///
/// Maps to the `Tracks` table in SYSTEM_DESIGN.md. Scalar metadata lives here;
/// artists are attached through the `TrackArtists` junction, and membership in
/// setlists / playlists / transitions is held by their respective join models.
@Model
final class Track {
    // MARK: Identity

    /// Domain identifier. A generated UUID is effectively unique on its own, so
    /// no `@Attribute(.unique)` constraint is applied: the constraint adds nothing
    /// for a UUID, brings upsert-on-collision semantics we don't want, and would
    /// close off a future CloudKit sync path. SwiftData tracks object identity
    /// internally (its own `PersistentIdentifier`) regardless.
    var id: UUID

    // MARK: Core metadata

    var title: String

    /// Beats per minute, stored as`Double`.
    var bpm: Double

    /// Harmonic key on the Camelot wheel. Stored as its raw `String` (e.g. "8A")
    /// so the persisted value is human-readable and stable across enum edits.
    var key: CamelotKey

    /// Track length in whole seconds.
    var duration: Int

    // MARK: Reserved / optional

    /// Reserved for the v2 Spotify integration. Unused in v1 — kept nullable so
    /// enabling Spotify later is a matter of populating it, not migrating.
    var spotifyID: String?

    /// User-authored notes: mixing ideas, memorable moments, reminders.
    var notes: String?

    // MARK: Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: Relationships

    // Every join cascades from BOTH parents, matching the schema's `ON DELETE
    // CASCADE` on both foreign keys: deleting a Track removes its rows in every
    // join, and deleting a container (Setlist/Playlist/Transition) or an Artist
    // removes its rows too. SwiftData handles a join with two cascade owners fine
    // (an earlier belief otherwise turned out to be a test-harness bug — see
    // ModelStoreTests). The junctions' to-one relationships are kept optional, which
    // SwiftData requires for the child side of a cascade delete.

    /// Artist credits for this track. Deleting a Track cascades to its `TrackArtist`
    /// rows (not to the Artists).
    @Relationship(deleteRule: .cascade, inverse: \TrackArtist.track)
    var trackArtists: [TrackArtist] = []

    /// Setlist placements referencing this track. Deleting a Track cascades to these.
    @Relationship(deleteRule: .cascade, inverse: \SetlistTrack.track)
    var setlistTracks: [SetlistTrack] = []

    /// Playlist memberships referencing this track. Deleting a Track cascades to these.
    @Relationship(deleteRule: .cascade, inverse: \PlaylistTrack.track)
    var playlistTracks: [PlaylistTrack] = []

    /// Transition placements referencing this track. Deleting a Track cascades to these.
    @Relationship(deleteRule: .cascade, inverse: \TransitionTrack.track)
    var transitionTracks: [TransitionTrack] = []

    // MARK: Init

    init(
        id: UUID = UUID(),
        title: String,
        bpm: Double,
        key: CamelotKey,
        duration: Int,
        spotifyID: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.bpm = bpm
        self.key = key
        self.duration = duration
        self.spotifyID = spotifyID
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - CamelotKey

/// Harmonic key on the Camelot wheel: numbers 1–12, each with an A (minor) and
/// B (major) side. This is the app's canonical key notation — importers convert
/// standard ("Am") or Open Key ("1m") notation into these values before insert.
///
/// `String`-backed so persisted rows stay readable and the raw values feed
/// directly into the compatibility primitive (SYSTEM_DESIGN.md § Compatibility).
///
/// Note: defined here for convenience while scaffolding. Once more of the model
/// layer exists, this is a natural candidate to move into its own file.
enum CamelotKey: String, Codable, CaseIterable, Identifiable {
    case k1A = "1A", k2A = "2A", k3A = "3A", k4A = "4A"
    case k5A = "5A", k6A = "6A", k7A = "7A", k8A = "8A"
    case k9A = "9A", k10A = "10A", k11A = "11A", k12A = "12A"
    case k1B = "1B", k2B = "2B", k3B = "3B", k4B = "4B"
    case k5B = "5B", k6B = "6B", k7B = "7B", k8B = "8B"
    case k9B = "9B", k10B = "10B", k11B = "11B", k12B = "12B"

    var id: String {
        rawValue
    }

    /// The wheel number, 1–12.
    var number: Int {
        Int(rawValue.dropLast())!
    }

    /// `true` for the A (minor) side, `false` for B (major).
    var isMinor: Bool {
        rawValue.hasSuffix("A")
    }

    static func isCompatible(key1: CamelotKey, key2: CamelotKey) -> Bool {
        let camelotDiff = abs(key1.number - key2.number)
        let sameMajorMinor = key1.rawValue.last == key2.rawValue.last

        // camelotDiff of 11 means keys wrap at 12 and 1
        return (camelotDiff == 0) || ((camelotDiff == 1 || camelotDiff == 11) && sameMajorMinor)
    }
}
