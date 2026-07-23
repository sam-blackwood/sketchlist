//
//  SetlistService.swift
//  SketchList
//

import Foundation
import SwiftData

enum SetlistServiceError: Error, Equatable, CustomStringConvertible {
    case duplicateName(String)
    case blankName

    var description: String {
        switch self {
        case let .duplicateName(name): "A setlist named \"\(name)\" already exists."
        case .blankName: "A setlist must have a non-empty name."
        }
    }
}

@MainActor
final class SetlistService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns the setlist whose `name` exactly matches, or `nil`. Backs the
    /// "no duplicate setlist names" rule.
    private func findSetlist(name: String) throws -> Setlist? {
        var descriptor = FetchDescriptor<Setlist>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Creates a new setlist. The name is trimmed of surrounding whitespace and must be
    /// non-empty and unique within setlists (case-sensitive; names may be reused across
    /// playlists/transitions).
    ///
    /// - Parameters:
    ///   - name: Display name. Trimmed; must be non-empty and not duplicate an existing setlist.
    ///   - descriptionText: Optional description of the setlist's purpose.
    ///   - notes: Optional longer working notes.
    /// - Returns: The newly created `Setlist`.
    /// - Throws: `SetlistServiceError.blankName` if the trimmed name is empty;
    ///   `.duplicateName` if a setlist with that name already exists.
    @discardableResult
    func insert(name: String, descriptionText: String?, notes: String?) throws -> Setlist {
        guard let name = name.trimmedNonEmpty else { throw SetlistServiceError.blankName }
        guard try findSetlist(name: name) == nil else { throw SetlistServiceError.duplicateName(name) }

        let setlist = Setlist(name: name, descriptionText: descriptionText, notes: notes)
        modelContext.insert(setlist)

        try modelContext.save()
        return setlist
    }

    /// Updates a setlist's metadata (full replacement) and bumps `updatedAt`. The name is
    /// trimmed and must stay non-empty and unique within setlists — renaming a setlist to
    /// its own current name is allowed. Passing `nil` for `descriptionText`/`notes` clears
    /// the respective field.
    ///
    /// - Parameters:
    ///   - setlist: The setlist to update.
    ///   - name: New name. Trimmed; must be non-empty and not collide with another setlist.
    ///   - descriptionText: New description, or `nil` to clear it.
    ///   - notes: New notes, or `nil` to clear them.
    /// - Throws: `SetlistServiceError.blankName` if the trimmed name is empty;
    ///   `.duplicateName` if another setlist already has that name.
    func update(_ setlist: Setlist, name: String, descriptionText: String? = nil, notes: String? = nil) throws {
        guard let name = name.trimmedNonEmpty else { throw SetlistServiceError.blankName }
        if let existing = try findSetlist(name: name), existing.id != setlist.id {
            throw SetlistServiceError.duplicateName(name)
        }

        setlist.name = name
        setlist.descriptionText = descriptionText
        setlist.notes = notes
        setlist.updatedAt = .now
        try modelContext.save()
    }

    /// Deletes a setlist. Its `SetlistTrack` rows are removed by the store cascade; the
    /// referenced tracks are left untouched in the library.
    func delete(_ setlist: Setlist) throws {
        modelContext.delete(setlist)
        try modelContext.save()
    }

    /// Adds `tracks` to `setlist`, in order. Each track is wrapped in a `SetlistTrack`
    /// membership row and spliced in at `index` (or appended when `index` is `nil`); all
    /// positions are then renumbered to stay contiguous. Setlists allow the same track
    /// more than once, so no de-duplication is performed.
    ///
    /// - Parameters:
    ///   - tracks: Tracks to add, in the order they should appear.
    ///   - setlist: The setlist to add them to.
    ///   - index: Insertion point within the setlist's current order; `nil` appends.
    func addTracks(_ tracks: [Track], to setlist: Setlist, at index: Int? = nil) throws {
        // The setlist's current membership rows, in order.
        var rows = setlist.setlistTracks.sorted { $0.position < $1.position }

        // Wrap each Track in a SetlistTrack — the join row *is* the membership record.
        // The position here is a placeholder; Ordering.insert reindexes everything below.
        let newRows = tracks.map { SetlistTrack(setlist: setlist, track: $0, position: 0) }
        for row in newRows {
            modelContext.insert(row)
        }

        Ordering.insert(newRows, at: index ?? rows.count, into: &rows)
        try modelContext.save()
    }

    /// Removes the given membership rows from `setlist`, then renumbers the survivors so
    /// positions stay contiguous. Takes `SetlistTrack`s (not `Track`s) because a setlist
    /// may contain the same track more than once — the row identifies the exact occurrence
    /// to remove. Rows not belonging to `setlist` simply have no effect on it. The removed
    /// rows' tracks are left untouched in the library.
    ///
    /// - Parameters:
    ///   - setlistTracks: The membership rows to remove.
    ///   - setlist: The setlist to remove them from.
    func removeTracks(_ setlistTracks: [SetlistTrack], from setlist: Setlist) throws {
        let removing = Set(setlistTracks.map(\.id))
        for row in setlistTracks {
            modelContext.delete(row)
        }

        let remaining = setlist.setlistTracks
            .filter { !removing.contains($0.id) }
            .sorted { $0.position < $1.position }
        Ordering.reindex(remaining)
        try modelContext.save()
    }
    
    /// Moves the row at `source` to `destination` within `setlist`, then renumbers so
    /// positions stay contiguous. `destination` follows the SwiftUI `onMove` convention
    /// (the offset to insert *before*, `0...count`). Indices are into the setlist's rows
    /// in their current position order.
    ///
    /// - Parameters:
    ///   - setlist: The setlist whose rows are being reordered.
    ///   - source: Index of the row to move (`0..<count`).
    ///   - destination: Where to move it (`0...count`).
    func moveTrack(in setlist: Setlist, from source: Int, to destination: Int) throws {
        var rows = setlist.setlistTracks.sorted { $0.position < $1.position }
        Ordering.move(&rows, from: source, to: destination)
        try modelContext.save()
    }
}
