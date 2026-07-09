//
//  ModelStoreTests.swift
//  SketchListTests
//
//  Exercises the SwiftData schema against a disk-free in-memory container.
//

import Foundation
import Testing
import SwiftData
@testable import SketchList

@MainActor  // mainContext is main-actor isolated, so the tests must run there.
struct ModelStoreTests {

    // Retain the container for the whole test. Grabbing `.mainContext` off a
    // throwaway `ModelContainer(...)` lets the container deallocate out from under
    // the context, which then traps on the next operation with no Swift error.
    // A stored property gives each test instance its own fresh, retained store.
    let container: ModelContainer

    init() throws {
        container = try .inMemory()
    }

    @Test func insertsAndFetchesTrack() throws {
        let context = container.mainContext

        context.insert(Track(title: "Midnight", bpm: 124, key: .k8A, duration: 312))
        try context.save()

        let tracks = try context.fetch(FetchDescriptor<Track>())
        #expect(tracks.count == 1)
        #expect(tracks.first?.key == .k8A)
    }

    /// Deleting a Setlist cascades to its join rows but leaves the Tracks intact —
    /// the schema's `SetlistTracks.setlist_id ON DELETE CASCADE`. The reverse
    /// direction (deleting the Track) is covered by `deletingTrackCascadesToJoinRows`.
    @Test func deletingSetlistCascadesToJoinRows() throws {
        let context = container.mainContext

        let track = Track(title: "Opener", bpm: 126, key: .k9A, duration: 280)
        let setlist = Setlist(name: "Friday Night")
        context.insert(track)
        context.insert(setlist)
        context.insert(SetlistTrack(setlist: setlist, track: track, position: 0))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<SetlistTrack>()) == 1)

        context.delete(setlist)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<SetlistTrack>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Track>()) == 1)
    }

    /// Deleting a Track cascades to its setlist join rows but leaves the Setlist —
    /// the schema's `SetlistTracks.track_id ON DELETE CASCADE`. Confirms a join with
    /// two cascade owners (Setlist and Track) is handled correctly.
    @Test func deletingTrackCascadesToJoinRows() throws {
        let context = container.mainContext

        let track = Track(title: "Opener", bpm: 126, key: .k9A, duration: 280)
        let setlist = Setlist(name: "Saturday Night")
        context.insert(track)
        context.insert(setlist)
        context.insert(SetlistTrack(setlist: setlist, track: track, position: 0))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<SetlistTrack>()) == 1)

        context.delete(track)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<SetlistTrack>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Setlist>()) == 1)
    }
}
