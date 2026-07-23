//
//  PlaylistServiceTests.swift
//  SketchListTests
//
//  Exercises PlaylistService (container CRUD + track membership) against an in-memory store.
//  Playlists differ from setlists in one way: a track appears at most once, so addTracks dedups.
//

import Foundation
import Testing
import SwiftData
@testable import SketchList

@MainActor
struct PlaylistServiceTests {

    let container: ModelContainer
    let service: PlaylistService

    init() throws {
        container = try .inMemory()
        service = PlaylistService(modelContext: container.mainContext)
    }

    // MARK: Helpers

    private var context: ModelContext { container.mainContext }

    func allPlaylists() throws -> [Playlist] {
        try context.fetch(FetchDescriptor<Playlist>())
    }

    func playlist(named name: String) throws -> Playlist? {
        var d = FetchDescriptor<Playlist>(predicate: #Predicate { $0.name == name })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func joinRowCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<PlaylistTrack>())
    }

    func allTracks() throws -> [Track] {
        try context.fetch(FetchDescriptor<Track>())
    }

    /// Creates and inserts a bare track (PlaylistService doesn't care about artists).
    func makeTrack(_ title: String) -> Track {
        let track = Track(title: title, bpm: 120, key: .k8A, duration: 100)
        context.insert(track)
        return track
    }

    /// The playlist's rows in position order.
    func orderedRows(in playlist: Playlist) -> [PlaylistTrack] {
        playlist.playlistTracks.sorted { $0.position < $1.position }
    }

    /// The titles of the playlist's tracks, in position order.
    func orderedTitles(in playlist: Playlist) -> [String] {
        orderedRows(in: playlist).compactMap { $0.track?.title }
    }
}

// MARK: - insert

@MainActor
extension PlaylistServiceTests {
    @Test("insert creates a playlist with its fields set")
    func insertCreatesPlaylist() throws {
        let playlist = try service.insert(name: "Late Night", descriptionText: "deep house", notes: "vibe")

        #expect(try allPlaylists().count == 1, "Exactly one playlist should exist after a single insert")
        #expect(playlist.name == "Late Night", "Name should be set from the argument")
        #expect(playlist.descriptionText == "deep house", "Description should be set from the argument")
        #expect(playlist.notes == "vibe", "Notes should be set from the argument")
    }

    @Test("insert trims surrounding whitespace from the name")
    func insertTrimsName() throws {
        let playlist = try service.insert(name: "  Late Night  ", descriptionText: nil, notes: nil)

        #expect(playlist.name == "Late Night", "The stored name should be trimmed")
    }

    @Test("insert rejects a blank name and persists nothing")
    func insertRejectsBlankName() throws {
        #expect(throws: PlaylistServiceError.blankName) {
            try service.insert(name: "   ", descriptionText: nil, notes: nil)
        }
        #expect(try allPlaylists().isEmpty, "A rejected insert must not create a playlist")
    }

    @Test("insert rejects a duplicate name")
    func insertRejectsDuplicateName() throws {
        try service.insert(name: "List A", descriptionText: nil, notes: nil)

        #expect(throws: PlaylistServiceError.duplicateName("List A")) {
            try service.insert(name: "List A", descriptionText: nil, notes: nil)
        }
        #expect(try allPlaylists().count == 1, "The duplicate insert must not create a second playlist")
    }

    @Test("insert treats differently-cased names as distinct (case-sensitive)")
    func insertIsCaseSensitive() throws {
        try service.insert(name: "List A", descriptionText: nil, notes: nil)

        #expect(throws: Never.self) {
            try service.insert(name: "list a", descriptionText: nil, notes: nil)
        }
        #expect(try allPlaylists().count == 2, "\"List A\" and \"list a\" should be two distinct playlists")
    }
}

// MARK: - update

@MainActor
extension PlaylistServiceTests {
    @Test("update replaces fields and bumps updatedAt")
    func updateReplacesFields() throws {
        let playlist = try service.insert(name: "Old", descriptionText: "old desc", notes: "old notes")
        let before = playlist.updatedAt

        try service.update(playlist, name: "New", descriptionText: "new desc", notes: "new notes")

        #expect(playlist.name == "New", "Name should be replaced")
        #expect(playlist.descriptionText == "new desc", "Description should be replaced")
        #expect(playlist.notes == "new notes", "Notes should be replaced")
        #expect(playlist.updatedAt >= before, "updatedAt should be bumped")
    }

    @Test("update clears description/notes when passed nil")
    func updateClearsNullableFields() throws {
        let playlist = try service.insert(name: "List", descriptionText: "desc", notes: "notes")

        try service.update(playlist, name: "List")

        #expect(playlist.descriptionText == nil, "Omitting description should clear it (full replacement)")
        #expect(playlist.notes == nil, "Omitting notes should clear it (full replacement)")
    }

    @Test("update rejects a blank name")
    func updateRejectsBlankName() throws {
        let playlist = try service.insert(name: "Original", descriptionText: nil, notes: nil)

        #expect(throws: PlaylistServiceError.blankName) {
            try service.update(playlist, name: "   ")
        }
        #expect(playlist.name == "Original", "A rejected update must not change the name")
    }

    @Test("update rejects renaming onto another playlist's name")
    func updateRejectsDuplicateName() throws {
        let a = try service.insert(name: "List A", descriptionText: nil, notes: nil)
        try service.insert(name: "List B", descriptionText: nil, notes: nil)

        #expect(throws: PlaylistServiceError.duplicateName("List B")) {
            try service.update(a, name: "List B")
        }
        #expect(a.name == "List A", "The rejected rename must leave the name unchanged")
    }

    @Test("update allows renaming a playlist to its own current name")
    func updateAllowsRenameToSelf() throws {
        let playlist = try service.insert(name: "List A", descriptionText: nil, notes: "keep")

        #expect(throws: Never.self) {
            try service.update(playlist, name: "List A", notes: "changed")
        }
        #expect(playlist.notes == "changed", "The no-op rename should still apply the other field changes")
    }
}

// MARK: - delete

@MainActor
extension PlaylistServiceTests {
    @Test("delete removes the playlist and its rows but leaves the tracks")
    func deleteRemovesPlaylistAndRows() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B")], to: playlist)

        try service.delete(playlist)

        #expect(try allPlaylists().isEmpty, "The playlist should be gone")
        #expect(try joinRowCount() == 0, "Its PlaylistTrack rows should be cascade-removed")
        #expect(try allTracks().count == 2, "The referenced tracks should remain in the library")
    }
}

// MARK: - addTracks

@MainActor
extension PlaylistServiceTests {
    @Test("addTracks appends tracks in order with contiguous positions and returns the new rows")
    func addTracksAppendsInOrder() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)

        let added = try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C")], to: playlist)

        #expect(added.count == 3, "All three distinct tracks should be added")
        #expect(orderedTitles(in: playlist) == ["A", "B", "C"], "Tracks should appear in the order added")
        #expect(orderedRows(in: playlist).map(\.position) == [0, 1, 2], "Positions should be contiguous 0..<count")
    }

    @Test("addTracks skips a track already in the playlist")
    func addTracksSkipsAlreadyPresent() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)
        let b = makeTrack("B")
        try service.addTracks([makeTrack("A"), b], to: playlist)

        let added = try service.addTracks([b, makeTrack("C")], to: playlist)

        #expect(added.count == 1, "Only the not-yet-present track (C) should be added")
        #expect(orderedTitles(in: playlist) == ["A", "B", "C"], "B should not be duplicated")
        #expect(orderedRows(in: playlist).map(\.position) == [0, 1, 2], "Positions should stay contiguous")
    }

    @Test("addTracks dedups repeats within the same call")
    func addTracksDedupsWithinCall() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)
        let track = makeTrack("A")

        let added = try service.addTracks([track, track], to: playlist)

        #expect(added.count == 1, "A track repeated in the same call should be added once")
        #expect(orderedRows(in: playlist).count == 1, "Only one row should exist for the track")
    }

    @Test("addTracks inserts at the given index")
    func addTracksInsertsAtIndex() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C")], to: playlist)

        try service.addTracks([makeTrack("X")], to: playlist, at: 1)

        #expect(orderedTitles(in: playlist) == ["A", "X", "B", "C"], "The new track should be spliced in at index 1")
        #expect(orderedRows(in: playlist).map(\.position) == [0, 1, 2, 3], "Positions should be renumbered contiguously")
    }
}

// MARK: - removeTracks

@MainActor
extension PlaylistServiceTests {
    @Test("removeTracks deletes the given rows and reindexes the survivors")
    func removeTracksReindexesSurvivors() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C"), makeTrack("D")], to: playlist)
        let rowB = orderedRows(in: playlist)[1]

        try service.removeTracks([rowB], from: playlist)

        #expect(orderedTitles(in: playlist) == ["A", "C", "D"], "The removed track should be gone")
        #expect(orderedRows(in: playlist).map(\.position) == [0, 1, 2], "Remaining positions should be contiguous")
        #expect(try allTracks().count == 4, "The removed row's track should remain in the library")
    }
}

// MARK: - moveTrack

@MainActor
extension PlaylistServiceTests {
    @Test("moveTrack reorders the rows and keeps positions contiguous")
    func moveTrackReorders() throws {
        let playlist = try service.insert(name: "List", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C"), makeTrack("D")], to: playlist)

        // onMove convention: moving index 1 to offset 3 lands it before original index 3.
        try service.moveTrack(in: playlist, from: 1, to: 3)

        #expect(orderedTitles(in: playlist) == ["A", "C", "B", "D"], "B should move to sit before D")
        #expect(orderedRows(in: playlist).map(\.position) == [0, 1, 2, 3], "Positions should stay contiguous")
    }
}
