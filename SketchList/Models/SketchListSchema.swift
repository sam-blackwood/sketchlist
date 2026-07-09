//
//  SketchListSchema.swift
//  SketchList
//
//  Single source of truth for the SwiftData schema. The on-disk app store, the
//  in-memory test/preview store, and any future migration plan all reference this
//  one model list so it can't drift between them — adding a model is a one-line
//  change here.
//

import Foundation
import SwiftData

enum SketchListSchema {

    /// Every `@Model` type in the app. Add new models here.
    static let models: [any PersistentModel.Type] = [
        Track.self, Artist.self, TrackArtist.self,
        Setlist.self, SetlistTrack.self,
        Playlist.self, PlaylistTrack.self,
        Transition.self, TransitionTrack.self,
    ]

    /// The composed schema built from `models`.
    static let schema = Schema(models)
}

// MARK: - ModelContainer factories

extension ModelContainer {

    /// The app's persistent container, stored at
    /// `~/Library/Application Support/SketchList/SketchList.store`.
    static func app() throws -> ModelContainer {
        // Application Support/SketchList/ won't exist on first launch, and
        // ModelConfiguration won't create intermediate directories — so make it.
        let dir = URL.applicationSupportDirectory.appending(path: "SketchList")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let storeURL = dir.appending(path: "SketchList.store")

        let config = ModelConfiguration(schema: SketchListSchema.schema, url: storeURL)

        do {
            return try ModelContainer(for: SketchListSchema.schema, configurations: [config])
        } catch {
            // DEV-ONLY fallback. There is no versioned migration plan yet (pre-1.0,
            // schema still in flux, no real user data worth preserving). If the
            // on-disk store is incompatible with the current schema, discard it and
            // recreate rather than trapping at launch — which would otherwise crash
            // both the app and the app-hosted test suite on every schema change.
            //
            // TODO: before shipping, replace this with a real SchemaMigrationPlan
            // and remove the destructive reset.
            let sidecars = ["SketchList.store", "SketchList.store-wal", "SketchList.store-shm"]
            for name in sidecars {
                try? FileManager.default.removeItem(at: dir.appending(path: name))
            }
            return try ModelContainer(for: SketchListSchema.schema, configurations: [config])
        }
    }

    /// Ephemeral, disk-free container for tests and previews. Each call yields a
    /// fresh, isolated store.
    static func inMemory() throws -> ModelContainer {
        let config = ModelConfiguration(schema: SketchListSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: SketchListSchema.schema, configurations: [config])
    }
}
