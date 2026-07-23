//
//  SetlistServiceTests.swift
//  SketchListTests
//
//  Exercises SetlistService (container CRUD + track membership) against an in-memory store.
//

import Foundation
import Testing
import SwiftData
@testable import SketchList

@MainActor
struct SetlistServiceTests {

    let container: ModelContainer
    let service: SetlistService

    init() throws {
        container = try .inMemory()
        service = SetlistService(modelContext: container.mainContext)
    }

    // MARK: Helpers

    private var context: ModelContext { container.mainContext }

    func allSetlists() throws -> [Setlist] {
        try context.fetch(FetchDescriptor<Setlist>())
    }

    func setlist(named name: String) throws -> Setlist? {
        var d = FetchDescriptor<Setlist>(predicate: #Predicate { $0.name == name })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func joinRowCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<SetlistTrack>())
    }

    func allTracks() throws -> [Track] {
        try context.fetch(FetchDescriptor<Track>())
    }

    /// Creates and inserts a bare track (SetlistService doesn't care about artists).
    func makeTrack(_ title: String) -> Track {
        let track = Track(title: title, bpm: 120, key: .k8A, duration: 100)
        context.insert(track)
        return track
    }

    /// The setlist's rows in position order.
    func orderedRows(in setlist: Setlist) -> [SetlistTrack] {
        setlist.setlistTracks.sorted { $0.position < $1.position }
    }

    /// The titles of the setlist's tracks, in position order.
    func orderedTitles(in setlist: Setlist) -> [String] {
        orderedRows(in: setlist).compactMap { $0.track?.title }
    }
}

// MARK: - insert

@MainActor
extension SetlistServiceTests {
    @Test("insert creates a setlist with its fields set")
    func insertCreatesSetlist() throws {
        let setlist = try service.insert(name: "Friday Night", descriptionText: "closing set", notes: "cue 0:48")

        #expect(try allSetlists().count == 1, "Exactly one setlist should exist after a single insert")
        #expect(setlist.name == "Friday Night", "Name should be set from the argument")
        #expect(setlist.descriptionText == "closing set", "Description should be set from the argument")
        #expect(setlist.notes == "cue 0:48", "Notes should be set from the argument")
    }

    @Test("insert trims surrounding whitespace from the name")
    func insertTrimsName() throws {
        let setlist = try service.insert(name: "  Friday Night  ", descriptionText: nil, notes: nil)

        #expect(setlist.name == "Friday Night", "The stored name should be trimmed")
    }

    @Test("insert rejects a blank name and persists nothing")
    func insertRejectsBlankName() throws {
        #expect(throws: SetlistServiceError.blankName) {
            try service.insert(name: "   ", descriptionText: nil, notes: nil)
        }
        #expect(try allSetlists().isEmpty, "A rejected insert must not create a setlist")
    }

    @Test("insert rejects a duplicate name")
    func insertRejectsDuplicateName() throws {
        try service.insert(name: "Set A", descriptionText: nil, notes: nil)

        #expect(throws: SetlistServiceError.duplicateName("Set A")) {
            try service.insert(name: "Set A", descriptionText: nil, notes: nil)
        }
        #expect(try allSetlists().count == 1, "The duplicate insert must not create a second setlist")
    }

    @Test("insert treats differently-cased names as distinct (case-sensitive)")
    func insertIsCaseSensitive() throws {
        try service.insert(name: "Set A", descriptionText: nil, notes: nil)

        #expect(throws: Never.self) {
            try service.insert(name: "set a", descriptionText: nil, notes: nil)
        }
        #expect(try allSetlists().count == 2, "\"Set A\" and \"set a\" should be two distinct setlists")
    }
}

// MARK: - update

@MainActor
extension SetlistServiceTests {
    @Test("update replaces fields and bumps updatedAt")
    func updateReplacesFields() throws {
        let setlist = try service.insert(name: "Old", descriptionText: "old desc", notes: "old notes")
        let before = setlist.updatedAt

        try service.update(setlist, name: "New", descriptionText: "new desc", notes: "new notes")

        #expect(setlist.name == "New", "Name should be replaced")
        #expect(setlist.descriptionText == "new desc", "Description should be replaced")
        #expect(setlist.notes == "new notes", "Notes should be replaced")
        #expect(setlist.updatedAt >= before, "updatedAt should be bumped")
    }

    @Test("update clears description/notes when passed nil")
    func updateClearsNullableFields() throws {
        let setlist = try service.insert(name: "Set", descriptionText: "desc", notes: "notes")

        try service.update(setlist, name: "Set")

        #expect(setlist.descriptionText == nil, "Omitting description should clear it (full replacement)")
        #expect(setlist.notes == nil, "Omitting notes should clear it (full replacement)")
    }

    @Test("update rejects a blank name")
    func updateRejectsBlankName() throws {
        let setlist = try service.insert(name: "Original", descriptionText: nil, notes: nil)

        #expect(throws: SetlistServiceError.blankName) {
            try service.update(setlist, name: "   ")
        }
        #expect(setlist.name == "Original", "A rejected update must not change the name")
    }

    @Test("update rejects renaming onto another setlist's name")
    func updateRejectsDuplicateName() throws {
        let a = try service.insert(name: "Set A", descriptionText: nil, notes: nil)
        try service.insert(name: "Set B", descriptionText: nil, notes: nil)

        #expect(throws: SetlistServiceError.duplicateName("Set B")) {
            try service.update(a, name: "Set B")
        }
        #expect(a.name == "Set A", "The rejected rename must leave the name unchanged")
    }

    @Test("update allows renaming a setlist to its own current name")
    func updateAllowsRenameToSelf() throws {
        let setlist = try service.insert(name: "Set A", descriptionText: nil, notes: "keep")

        #expect(throws: Never.self) {
            try service.update(setlist, name: "Set A", notes: "changed")
        }
        #expect(setlist.notes == "changed", "The no-op rename should still apply the other field changes")
    }
}

// MARK: - delete

@MainActor
extension SetlistServiceTests {
    @Test("delete removes the setlist and its rows but leaves the tracks")
    func deleteRemovesSetlistAndRows() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B")], to: setlist)

        try service.delete(setlist)

        #expect(try allSetlists().isEmpty, "The setlist should be gone")
        #expect(try joinRowCount() == 0, "Its SetlistTrack rows should be cascade-removed")
        #expect(try allTracks().count == 2, "The referenced tracks should remain in the library")
    }
}

// MARK: - addTracks

@MainActor
extension SetlistServiceTests {
    @Test("addTracks appends tracks in order with contiguous positions")
    func addTracksAppendsInOrder() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)

        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C")], to: setlist)

        #expect(orderedTitles(in: setlist) == ["A", "B", "C"], "Tracks should appear in the order added")
        #expect(orderedRows(in: setlist).map(\.position) == [0, 1, 2], "Positions should be contiguous 0..<count")
    }

    @Test("addTracks appends onto an existing list")
    func addTracksAppendsOntoExisting() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B")], to: setlist)

        try service.addTracks([makeTrack("C")], to: setlist)

        #expect(orderedTitles(in: setlist) == ["A", "B", "C"], "New tracks should append after existing ones")
        #expect(orderedRows(in: setlist).map(\.position) == [0, 1, 2], "Positions should stay contiguous")
    }

    @Test("addTracks allows the same track more than once")
    func addTracksAllowsDuplicates() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        let track = makeTrack("A")

        try service.addTracks([track, track], to: setlist)

        #expect(orderedTitles(in: setlist) == ["A", "A"], "The same track should be allowed twice in a setlist")
        #expect(orderedRows(in: setlist).count == 2, "Two distinct rows should exist for the duplicate track")
    }

    @Test("addTracks inserts at the given index")
    func addTracksInsertsAtIndex() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C")], to: setlist)

        try service.addTracks([makeTrack("X")], to: setlist, at: 1)

        #expect(orderedTitles(in: setlist) == ["A", "X", "B", "C"], "The new track should be spliced in at index 1")
        #expect(orderedRows(in: setlist).map(\.position) == [0, 1, 2, 3], "Positions should be renumbered contiguously")
    }
}

// MARK: - removeTracks

@MainActor
extension SetlistServiceTests {
    @Test("removeTracks deletes the given rows and reindexes the survivors")
    func removeTracksReindexesSurvivors() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C"), makeTrack("D")], to: setlist)
        let rowB = orderedRows(in: setlist)[1]

        try service.removeTracks([rowB], from: setlist)

        #expect(orderedTitles(in: setlist) == ["A", "C", "D"], "The removed track should be gone")
        #expect(orderedRows(in: setlist).map(\.position) == [0, 1, 2], "Remaining positions should be contiguous")
        #expect(try allTracks().count == 4, "The removed row's track should remain in the library")
    }

    @Test("removeTracks removes only the specified occurrence of a duplicated track")
    func removeTracksRemovesOneOccurrence() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        let track = makeTrack("A")
        try service.addTracks([track, track], to: setlist)
        let firstRow = orderedRows(in: setlist)[0]

        try service.removeTracks([firstRow], from: setlist)

        #expect(orderedRows(in: setlist).count == 1, "Only the specified occurrence should be removed")
        #expect(orderedRows(in: setlist).map(\.position) == [0], "The survivor should be reindexed to position 0")
    }
}

// MARK: - moveTrack

@MainActor
extension SetlistServiceTests {
    @Test("moveTrack reorders the rows and keeps positions contiguous")
    func moveTrackReorders() throws {
        let setlist = try service.insert(name: "Set", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C"), makeTrack("D")], to: setlist)

        // onMove convention: moving index 1 to offset 3 lands it before original index 3.
        try service.moveTrack(in: setlist, from: 1, to: 3)

        #expect(orderedTitles(in: setlist) == ["A", "C", "B", "D"], "B should move to sit before D")
        #expect(orderedRows(in: setlist).map(\.position) == [0, 1, 2, 3], "Positions should stay contiguous")
    }
}
