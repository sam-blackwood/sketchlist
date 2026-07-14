//
//  TrackServiceTests.swift
//  SketchList
//

import Foundation
@testable import SketchList
import SwiftData
import Testing

@MainActor
struct TrackServiceTests {
    let container: ModelContainer
    let service: TrackService

    init() throws {
        container = try .inMemory()
        service = TrackService(modelContext: container.mainContext)
    }

    // MARK: Fetch helpers (for assertions)

    private var context: ModelContext {
        container.mainContext
    }

    /// Every track currently in the store.
    func allTracks() throws -> [Track] {
        try context.fetch(FetchDescriptor<Track>())
    }

    /// Every artist currently in the store.
    func allArtists() throws -> [Artist] {
        try context.fetch(FetchDescriptor<Artist>())
    }

    /// The artist matching `name` (case-insensitively via `Artist.normalize`), or `nil`.
    func artist(named name: String) throws -> Artist? {
        let key = Artist.normalize(name)
        var descriptor = FetchDescriptor<Artist>(predicate: #Predicate { $0.normalizedName == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Number of `TrackArtist` credit rows in the store.
    func creditCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<TrackArtist>())
    }
}

// MARK: - insert

@MainActor
extension TrackServiceTests {
    @Test("insert creates a track with its scalar fields and one credit per artist")
    func insertCreatesTrackWithCredits() throws {
        let track = try service.insert(
            title: "Good Things Fall Apart",
            artists: ["Illenium", "Jon Bellion"],
            bpm: 144,
            key: .k10B,
            duration: 219
        )

        #expect(try allTracks().count == 1, "Exactly one track should exist after a single insert")
        #expect(track.title == "Good Things Fall Apart", "Title should be set from the argument")
        #expect(track.trackArtists.count == 2, "Both artists should be credited on the track")
        #expect(try allArtists().count == 2, "Two distinct artists should have been created")
    }

    @Test("insert persists all scalar fields on the track")
    func insertPersistsScalarFields() throws {
        let track = try service.insert(
            title: "Reverie",
            artists: ["Illenium"],
            bpm: 174,
            key: .k8B,
            duration: 205,
            spotifyID: "spotify:track:abc123",
            notes: "start transition at 0:48"
        )

        #expect(track.title == "Reverie", "Title should round-trip")
        #expect(track.bpm == 174, "BPM should round-trip")
        #expect(track.key == .k8B, "Key should round-trip")
        #expect(track.duration == 205, "Duration should round-trip")
        #expect(track.spotifyID == "spotify:track:abc123", "spotifyID should round-trip")
        #expect(track.notes == "start transition at 0:48", "Notes should round-trip")
    }

    @Test("insert rejects a track with no (effective) artists and persists nothing")
    func insertRejectsNoArtists() throws {
        #expect(throws: TrackServiceError.noArtists) {
            try service.insert(title: "Untitled", artists: [], bpm: 120, key: .k1A, duration: 100)
        }
        #expect(throws: TrackServiceError.noArtists) {
            // A set of only blank/whitespace names is effectively no artists.
            try service.insert(title: "Untitled", artists: ["  ", ""], bpm: 120, key: .k1A, duration: 100)
        }

        #expect(try allTracks().isEmpty, "A rejected insert must not create a track")
        #expect(try allArtists().isEmpty, "A rejected insert must not create any artist")
    }

    @Test("insert reuses an existing artist across two tracks rather than duplicating")
    func insertReusesArtistAcrossTracks() throws {
        try service.insert(title: "Track A", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)
        try service.insert(title: "Track B", artists: ["Illenium"], bpm: 150, key: .k9B, duration: 210)

        #expect(try allTracks().count == 2, "Both tracks should exist")
        #expect(try allArtists().count == 1, "The shared artist should be stored once, not duplicated")
        #expect(try creditCount() == 2, "Each track should have its own credit to the shared artist")
    }

    @Test("insert dedups artists case-insensitively and keeps the first-seen casing")
    func insertDedupsCaseInsensitively() throws {
        try service.insert(title: "Track A", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)
        try service.insert(title: "Track B", artists: ["illenium"], bpm: 150, key: .k9B, duration: 210)

        #expect(try allArtists().count == 1, "\"Illenium\" and \"illenium\" should resolve to one artist")
        #expect(try artist(named: "ILLENIUM")?.name == "Illenium",
                "The stored display name should keep the first-seen casing (\"Illenium\")")
    }

    @Test("insert dedups casing variants within a single call to one artist and one credit")
    func insertDedupsWithinSingleCall() throws {
        let track = try service.insert(
            title: "Track A",
            artists: ["Illenium", "illenium", "ILLENIUM"],
            bpm: 140,
            key: .k8B,
            duration: 200
        )

        #expect(try allArtists().count == 1, "All casing variants in one call should collapse to one artist")
        #expect(track.trackArtists.count == 1, "The track should receive exactly one credit, not three")
    }

    @Test("insert trims artist names and skips blank ones")
    func insertTrimsAndSkipsBlankArtists() throws {
        let track = try service.insert(
            title: "Track A",
            artists: ["  Illenium  ", "   ", ""],
            bpm: 140,
            key: .k8B,
            duration: 200
        )

        #expect(track.trackArtists.count == 1, "Only the one non-blank name should be credited")
        #expect(try allArtists().count == 1, "Only one artist should be created")
        #expect(try artist(named: "Illenium")?.name == "Illenium",
                "The stored name should be trimmed of surrounding whitespace")
    }

    @Test("insert treats a name and its whitespace-padded form as the same artist")
    func insertDedupsAcrossWhitespace() throws {
        try service.insert(title: "Track A", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)
        try service.insert(title: "Track B", artists: ["  Illenium  "], bpm: 150, key: .k9B, duration: 210)

        #expect(try allArtists().count == 1, "Whitespace-padded and trimmed names should resolve to one artist")
        #expect(try creditCount() == 2, "Each track keeps its own credit to the shared artist")
    }
}

// MARK: - update

@MainActor
extension TrackServiceTests {
    @Test("update replaces the track's scalar fields and bumps updatedAt")
    func updateReplacesScalarFields() throws {
        let track = try service.insert(title: "Old", artists: ["Illenium"], bpm: 120, key: .k1A, duration: 100)
        let before = track.updatedAt

        try service.update(
            track,
            title: "New",
            artists: ["Illenium"],
            bpm: 128,
            key: .k8B,
            duration: 240,
            spotifyID: "spotify:track:xyz",
            notes: "cue at 0:32"
        )

        #expect(track.title == "New", "Title should be replaced")
        #expect(track.bpm == 128, "BPM should be replaced")
        #expect(track.key == .k8B, "Key should be replaced")
        #expect(track.duration == 240, "Duration should be replaced")
        #expect(track.spotifyID == "spotify:track:xyz", "spotifyID should be replaced")
        #expect(track.notes == "cue at 0:32", "Notes should be replaced")
        #expect(track.updatedAt >= before, "updatedAt should be bumped to at least the previous value")
    }

    @Test("update clears nullable fields when passed nil")
    func updateClearsNullableFields() throws {
        let track = try service.insert(
            title: "Track",
            artists: ["Illenium"],
            bpm: 120,
            key: .k1A,
            duration: 100,
            spotifyID: "spotify:track:abc",
            notes: "some notes"
        )

        try service.update(track, title: "Track", artists: ["Illenium"], bpm: 120, key: .k1A, duration: 100)

        #expect(track.spotifyID == nil, "Omitting spotifyID should clear it (full-replacement semantics)")
        #expect(track.notes == nil, "Omitting notes should clear it (full-replacement semantics)")
    }

    @Test("update adds a newly listed artist while keeping existing credits")
    func updateAddsArtist() throws {
        let track = try service.insert(title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        try service.update(track, title: "Track", artists: ["Illenium", "Jon Bellion"], bpm: 140, key: .k8B, duration: 200)

        #expect(track.trackArtists.count == 2, "The new artist should be added alongside the kept one")
        #expect(try allArtists().count == 2, "A new Artist row should exist for the added name")
    }

    @Test("update removes a dropped artist's credit")
    func updateRemovesArtistCredit() throws {
        let track = try service.insert(
            title: "Track",
            artists: ["Illenium", "Jon Bellion"],
            bpm: 140,
            key: .k8B,
            duration: 200
        )

        try service.update(track, title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        #expect(track.trackArtists.count == 1, "The dropped artist's credit should be removed")
        #expect(track.trackArtists.first?.artist?.name == "Illenium", "The kept artist should remain credited")
    }

    @Test("update leaves shared artists untouched — no duplicate credits")
    func updateKeepsSharedArtistsWithoutDuplicating() throws {
        let track = try service.insert(title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        // Re-submit the same artist set.
        try service.update(track, title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        #expect(track.trackArtists.count == 1, "Re-listing the same artist must not create a duplicate credit")
        #expect(try creditCount() == 1, "There should still be exactly one credit row")
    }

    @Test("update with a casing-only artist change is a no-op on identity")
    func updateCasingOnlyChangeIsNoOp() throws {
        let track = try service.insert(title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)
        let artistID = track.trackArtists.first?.artist?.id

        try service.update(track, title: "Track", artists: ["illenium"], bpm: 140, key: .k8B, duration: 200)

        #expect(try allArtists().count == 1, "A casing-only change must not create a second artist")
        #expect(track.trackArtists.count == 1, "There should still be exactly one credit")
        #expect(track.trackArtists.first?.artist?.id == artistID, "The credit should still point at the same artist")
        #expect(try artist(named: "illenium")?.name == "Illenium", "The stored casing should be unchanged")
    }

    @Test("update prunes an artist left with no other tracks")
    func updatePrunesOrphanedArtist() throws {
        let track = try service.insert(
            title: "Track",
            artists: ["Illenium", "Jon Bellion"],
            bpm: 140,
            key: .k8B,
            duration: 200
        )

        // Drop Jon Bellion, who is credited only on this track.
        try service.update(track, title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        #expect(try allArtists().count == 1, "The dropped artist, now on no tracks, should be pruned")
        #expect(try artist(named: "Jon Bellion") == nil, "Jon Bellion should no longer exist")
        #expect(try artist(named: "Illenium") != nil, "Illenium, still credited, should remain")
    }

    @Test("update keeps a dropped artist that is still credited on another track")
    func updateKeepsArtistStillOnAnotherTrack() throws {
        // Illenium is on two tracks; Jon Bellion only on the first.
        let trackA = try service.insert(
            title: "Track A",
            artists: ["Illenium", "Jon Bellion"],
            bpm: 140,
            key: .k8B,
            duration: 200
        )
        try service.insert(title: "Track B", artists: ["Illenium"], bpm: 150, key: .k9B, duration: 210)

        // Drop Illenium from Track A — but Illenium is still on Track B.
        try service.update(trackA, title: "Track A", artists: ["Jon Bellion"], bpm: 140, key: .k8B, duration: 200)

        #expect(try artist(named: "Illenium") != nil, "Illenium should survive — still credited on Track B")
        #expect(try allArtists().count == 2, "Both artists should still exist")
    }

    @Test("update rejects an empty artist set and leaves the track unchanged")
    func updateRejectsNoArtists() throws {
        let track = try service.insert(title: "Original", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        #expect(throws: TrackServiceError.noArtists) {
            try service.update(track, title: "Changed", artists: [], bpm: 999, key: .k1A, duration: 1)
        }

        #expect(track.title == "Original", "A rejected update must not change scalar fields (guard runs first)")
        #expect(track.bpm == 140, "A rejected update must not change scalar fields")
        #expect(track.trackArtists.count == 1, "A rejected update must leave the existing credit intact")
    }
}

// MARK: - delete

@MainActor
extension TrackServiceTests {
    @Test("delete removes the track and its credits")
    func deleteRemovesTrackAndCredits() throws {
        let track = try service.insert(title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        try service.delete(track)

        #expect(try allTracks().isEmpty, "The track should be gone")
        #expect(try creditCount() == 0, "The track's credits should be cascade-removed")
    }

    @Test("delete prunes an artist left with no other tracks")
    func deletePrunesOrphanedArtist() throws {
        let track = try service.insert(title: "Track", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)

        try service.delete(track)

        #expect(try allArtists().isEmpty, "An artist credited only on the deleted track should be pruned")
    }

    @Test("delete keeps an artist still credited on another track")
    func deleteKeepsArtistOnAnotherTrack() throws {
        let trackA = try service.insert(title: "Track A", artists: ["Illenium"], bpm: 140, key: .k8B, duration: 200)
        try service.insert(title: "Track B", artists: ["Illenium"], bpm: 150, key: .k9B, duration: 210)

        try service.delete(trackA)

        #expect(try allTracks().count == 1, "Track B should remain")
        #expect(try allArtists().count == 1, "Illenium should survive — still credited on Track B")
        #expect(try creditCount() == 1, "Only Track B's credit should remain")
    }

    @Test("delete prunes only the orphaned artists, keeping the still-credited ones")
    func deletePrunesOnlyOrphans() throws {
        // Track A: Illenium + Jon Bellion. Track B: Illenium only.
        let trackA = try service.insert(
            title: "Track A",
            artists: ["Illenium", "Jon Bellion"],
            bpm: 140,
            key: .k8B,
            duration: 200
        )
        try service.insert(title: "Track B", artists: ["Illenium"], bpm: 150, key: .k9B, duration: 210)

        // Deleting Track A orphans Jon Bellion, but Illenium is still on Track B.
        try service.delete(trackA)

        #expect(try artist(named: "Jon Bellion") == nil, "Jon Bellion, now on no tracks, should be pruned")
        #expect(try artist(named: "Illenium") != nil, "Illenium should survive — still on Track B")
        #expect(try allArtists().count == 1, "Only the still-credited artist should remain")
    }
}
