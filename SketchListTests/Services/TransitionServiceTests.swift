//
//  TransitionServiceTests.swift
//  SketchListTests
//
//  Exercises TransitionService (container CRUD + track membership) against an in-memory store.
//  Like setlists, transitions allow the same track more than once (and a single track is valid).
//

import Foundation
import Testing
import SwiftData
@testable import SketchList

@MainActor
struct TransitionServiceTests {

    let container: ModelContainer
    let service: TransitionService

    init() throws {
        container = try .inMemory()
        service = TransitionService(modelContext: container.mainContext)
    }

    // MARK: Helpers

    private var context: ModelContext { container.mainContext }

    func allTransitions() throws -> [Transition] {
        try context.fetch(FetchDescriptor<Transition>())
    }

    func transition(named name: String) throws -> Transition? {
        var d = FetchDescriptor<Transition>(predicate: #Predicate { $0.name == name })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    func joinRowCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<TransitionTrack>())
    }

    func allTracks() throws -> [Track] {
        try context.fetch(FetchDescriptor<Track>())
    }

    /// Creates and inserts a bare track (TransitionService doesn't care about artists).
    func makeTrack(_ title: String) -> Track {
        let track = Track(title: title, bpm: 120, key: .k8A, duration: 100)
        context.insert(track)
        return track
    }

    /// The transition's rows in position order.
    func orderedRows(in transition: Transition) -> [TransitionTrack] {
        transition.transitionTracks.sorted { $0.position < $1.position }
    }

    /// The titles of the transition's tracks, in position order.
    func orderedTitles(in transition: Transition) -> [String] {
        orderedRows(in: transition).compactMap { $0.track?.title }
    }
}

// MARK: - insert

@MainActor
extension TransitionServiceTests {
    @Test("insert creates a transition with its fields set")
    func insertCreatesTransition() throws {
        let transition = try service.insert(name: "Energy Lift", descriptionText: "into peak", notes: "mix on 2")

        #expect(try allTransitions().count == 1, "Exactly one transition should exist after a single insert")
        #expect(transition.name == "Energy Lift", "Name should be set from the argument")
        #expect(transition.descriptionText == "into peak", "Description should be set from the argument")
        #expect(transition.notes == "mix on 2", "Notes should be set from the argument")
    }

    @Test("insert trims surrounding whitespace from the name")
    func insertTrimsName() throws {
        let transition = try service.insert(name: "  Energy Lift  ", descriptionText: nil, notes: nil)

        #expect(transition.name == "Energy Lift", "The stored name should be trimmed")
    }

    @Test("insert rejects a blank name and persists nothing")
    func insertRejectsBlankName() throws {
        #expect(throws: TransitionServiceError.blankName) {
            try service.insert(name: "   ", descriptionText: nil, notes: nil)
        }
        #expect(try allTransitions().isEmpty, "A rejected insert must not create a transition")
    }

    @Test("insert rejects a duplicate name")
    func insertRejectsDuplicateName() throws {
        try service.insert(name: "Move A", descriptionText: nil, notes: nil)

        #expect(throws: TransitionServiceError.duplicateName("Move A")) {
            try service.insert(name: "Move A", descriptionText: nil, notes: nil)
        }
        #expect(try allTransitions().count == 1, "The duplicate insert must not create a second transition")
    }

    @Test("insert treats differently-cased names as distinct (case-sensitive)")
    func insertIsCaseSensitive() throws {
        try service.insert(name: "Move A", descriptionText: nil, notes: nil)

        #expect(throws: Never.self) {
            try service.insert(name: "move a", descriptionText: nil, notes: nil)
        }
        #expect(try allTransitions().count == 2, "\"Move A\" and \"move a\" should be two distinct transitions")
    }
}

// MARK: - update

@MainActor
extension TransitionServiceTests {
    @Test("update replaces fields and bumps updatedAt")
    func updateReplacesFields() throws {
        let transition = try service.insert(name: "Old", descriptionText: "old desc", notes: "old notes")
        let before = transition.updatedAt

        try service.update(transition, name: "New", descriptionText: "new desc", notes: "new notes")

        #expect(transition.name == "New", "Name should be replaced")
        #expect(transition.descriptionText == "new desc", "Description should be replaced")
        #expect(transition.notes == "new notes", "Notes should be replaced")
        #expect(transition.updatedAt >= before, "updatedAt should be bumped")
    }

    @Test("update clears description/notes when passed nil")
    func updateClearsNullableFields() throws {
        let transition = try service.insert(name: "Move", descriptionText: "desc", notes: "notes")

        try service.update(transition, name: "Move")

        #expect(transition.descriptionText == nil, "Omitting description should clear it (full replacement)")
        #expect(transition.notes == nil, "Omitting notes should clear it (full replacement)")
    }

    @Test("update rejects a blank name")
    func updateRejectsBlankName() throws {
        let transition = try service.insert(name: "Original", descriptionText: nil, notes: nil)

        #expect(throws: TransitionServiceError.blankName) {
            try service.update(transition, name: "   ")
        }
        #expect(transition.name == "Original", "A rejected update must not change the name")
    }

    @Test("update rejects renaming onto another transition's name")
    func updateRejectsDuplicateName() throws {
        let a = try service.insert(name: "Move A", descriptionText: nil, notes: nil)
        try service.insert(name: "Move B", descriptionText: nil, notes: nil)

        #expect(throws: TransitionServiceError.duplicateName("Move B")) {
            try service.update(a, name: "Move B")
        }
        #expect(a.name == "Move A", "The rejected rename must leave the name unchanged")
    }

    @Test("update allows renaming a transition to its own current name")
    func updateAllowsRenameToSelf() throws {
        let transition = try service.insert(name: "Move A", descriptionText: nil, notes: "keep")

        #expect(throws: Never.self) {
            try service.update(transition, name: "Move A", notes: "changed")
        }
        #expect(transition.notes == "changed", "The no-op rename should still apply the other field changes")
    }
}

// MARK: - delete

@MainActor
extension TransitionServiceTests {
    @Test("delete removes the transition and its rows but leaves the tracks")
    func deleteRemovesTransitionAndRows() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B")], to: transition)

        try service.delete(transition)

        #expect(try allTransitions().isEmpty, "The transition should be gone")
        #expect(try joinRowCount() == 0, "Its TransitionTrack rows should be cascade-removed")
        #expect(try allTracks().count == 2, "The referenced tracks should remain in the library")
    }
}

// MARK: - addTracks

@MainActor
extension TransitionServiceTests {
    @Test("addTracks appends tracks in order with contiguous positions")
    func addTracksAppendsInOrder() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)

        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C")], to: transition)

        #expect(orderedTitles(in: transition) == ["A", "B", "C"], "Tracks should appear in the order added")
        #expect(orderedRows(in: transition).map(\.position) == [0, 1, 2], "Positions should be contiguous 0..<count")
    }

    @Test("addTracks supports a single-track transition")
    func addTracksSupportsSingleTrack() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)

        try service.addTracks([makeTrack("A")], to: transition)

        #expect(orderedTitles(in: transition) == ["A"], "A one-track transition should be valid")
        #expect(orderedRows(in: transition).map(\.position) == [0], "The single row should be at position 0")
    }

    @Test("addTracks allows the same track more than once")
    func addTracksAllowsDuplicates() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)
        let track = makeTrack("A")

        try service.addTracks([track, track], to: transition)

        #expect(orderedTitles(in: transition) == ["A", "A"], "The same track should be allowed twice in a transition")
        #expect(orderedRows(in: transition).count == 2, "Two distinct rows should exist for the duplicate track")
    }

    @Test("addTracks inserts at the given index")
    func addTracksInsertsAtIndex() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C")], to: transition)

        try service.addTracks([makeTrack("X")], to: transition, at: 1)

        #expect(orderedTitles(in: transition) == ["A", "X", "B", "C"], "The new track should be spliced in at index 1")
        #expect(orderedRows(in: transition).map(\.position) == [0, 1, 2, 3], "Positions should be renumbered contiguously")
    }
}

// MARK: - removeTracks

@MainActor
extension TransitionServiceTests {
    @Test("removeTracks deletes the given rows and reindexes the survivors")
    func removeTracksReindexesSurvivors() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C"), makeTrack("D")], to: transition)
        let rowB = orderedRows(in: transition)[1]

        try service.removeTracks([rowB], from: transition)

        #expect(orderedTitles(in: transition) == ["A", "C", "D"], "The removed track should be gone")
        #expect(orderedRows(in: transition).map(\.position) == [0, 1, 2], "Remaining positions should be contiguous")
        #expect(try allTracks().count == 4, "The removed row's track should remain in the library")
    }

    @Test("removeTracks removes only the specified occurrence of a duplicated track")
    func removeTracksRemovesOneOccurrence() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)
        let track = makeTrack("A")
        try service.addTracks([track, track], to: transition)
        let firstRow = orderedRows(in: transition)[0]

        try service.removeTracks([firstRow], from: transition)

        #expect(orderedRows(in: transition).count == 1, "Only the specified occurrence should be removed")
        #expect(orderedRows(in: transition).map(\.position) == [0], "The survivor should be reindexed to position 0")
    }
}

// MARK: - moveTrack

@MainActor
extension TransitionServiceTests {
    @Test("moveTrack reorders the rows and keeps positions contiguous")
    func moveTrackReorders() throws {
        let transition = try service.insert(name: "Move", descriptionText: nil, notes: nil)
        try service.addTracks([makeTrack("A"), makeTrack("B"), makeTrack("C"), makeTrack("D")], to: transition)

        // onMove convention: moving index 1 to offset 3 lands it before original index 3.
        try service.moveTrack(in: transition, from: 1, to: 3)

        #expect(orderedTitles(in: transition) == ["A", "C", "B", "D"], "B should move to sit before D")
        #expect(orderedRows(in: transition).map(\.position) == [0, 1, 2, 3], "Positions should stay contiguous")
    }
}
