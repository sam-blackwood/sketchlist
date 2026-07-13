//
//  Artist.swift
//  SketchList
//
//  A performer credited on one or more tracks. Artists are their own entity so
//  the same performer is stored once and shared across every track they appear
//  on (see SYSTEM_DESIGN.md § Data Model).
//

import Foundation
import SwiftData

/// A single artist in the user's library.
///
/// Maps to the `Artists` table in SYSTEM_DESIGN.md. An artist carries only a
/// name; the tracks they're credited on are reached through the `TrackArtists`
/// junction, keeping the many-to-many relationship normalized.
@Model
final class Artist {
    // MARK: Identity

    /// Domain identifier. Plain UUID, no `.unique` constraint — see Track for the
    /// rationale. SwiftData tracks object identity internally regardless.
    var id: UUID

    // MARK: Core metadata

    /// The artist's display name.
    var name: String

    // MARK: Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: Relationships

    /// Junction rows linking this artist to the tracks they're credited on.
    /// Deleting an Artist cascades to its `TrackArtist` rows (not to the Tracks).
    /// Both parents (Track and Artist) cascade into `TrackArtist`, matching the
    /// schema's `ON DELETE CASCADE` on both foreign keys.
    @Relationship(deleteRule: .cascade, inverse: \TrackArtist.artist)
    var trackArtists: [TrackArtist] = []

    // MARK: Init

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
