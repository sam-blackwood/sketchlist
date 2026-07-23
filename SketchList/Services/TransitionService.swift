//
//  TransitionService.swift
//  SketchList
//

import Foundation
import SwiftData

enum TransitionServiceError: Error, Equatable, CustomStringConvertible {
    case duplicateName(String)
    case blankName

    var description: String {
        switch self {
        case let .duplicateName(name): "A transition named \"\(name)\" already exists."
        case .blankName: "A transition must have a non-empty name."
        }
    }
}

@MainActor
final class TransitionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns the transition whose `name` exactly matches, or `nil`. Backs the
    /// "no duplicate transition names" rule.
    private func findTransition(name: String) throws -> Transition? {
        var descriptor = FetchDescriptor<Transition>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Creates a new transition. The name is trimmed of surrounding whitespace and must be
    /// non-empty and unique within transitions (case-sensitive; names may be reused across
    /// setlists/playlists).
    ///
    /// - Parameters:
    ///   - name: Display name. Trimmed; must be non-empty and not duplicate an existing transition.
    ///   - descriptionText: Optional description of the transition's purpose.
    ///   - notes: Optional longer working notes.
    /// - Returns: The newly created `Transition`.
    /// - Throws: `TransitionServiceError.blankName` if the trimmed name is empty;
    ///   `.duplicateName` if a transition with that name already exists.
    @discardableResult
    func insert(name: String, descriptionText: String?, notes: String?) throws -> Transition {
        guard let name = name.trimmedNonEmpty else { throw TransitionServiceError.blankName }
        guard try findTransition(name: name) == nil else { throw TransitionServiceError.duplicateName(name) }

        let transition = Transition(name: name, descriptionText: descriptionText, notes: notes)
        modelContext.insert(transition)

        try modelContext.save()
        return transition
    }

    /// Updates a transition's metadata (full replacement) and bumps `updatedAt`. The name is
    /// trimmed and must stay non-empty and unique within transitions — renaming a transition
    /// to its own current name is allowed. Passing `nil` for `descriptionText`/`notes` clears
    /// the respective field.
    ///
    /// - Parameters:
    ///   - transition: The transition to update.
    ///   - name: New name. Trimmed; must be non-empty and not collide with another transition.
    ///   - descriptionText: New description, or `nil` to clear it.
    ///   - notes: New notes, or `nil` to clear them.
    /// - Throws: `TransitionServiceError.blankName` if the trimmed name is empty;
    ///   `.duplicateName` if another transition already has that name.
    func update(_ transition: Transition, name: String, descriptionText: String? = nil, notes: String? = nil) throws {
        guard let name = name.trimmedNonEmpty else { throw TransitionServiceError.blankName }
        if let existing = try findTransition(name: name), existing.id != transition.id {
            throw TransitionServiceError.duplicateName(name)
        }

        transition.name = name
        transition.descriptionText = descriptionText
        transition.notes = notes
        transition.updatedAt = .now
        try modelContext.save()
    }

    /// Deletes a transition. Its `TransitionTrack` rows are removed by the store cascade; the
    /// referenced tracks are left untouched in the library.
    func delete(_ transition: Transition) throws {
        modelContext.delete(transition)
        try modelContext.save()
    }

    /// Adds `tracks` to `transition`, in order. Each track is wrapped in a `TransitionTrack`
    /// membership row and spliced in at `index` (or appended when `index` is `nil`); all
    /// positions are then renumbered to stay contiguous. Transitions allow the same track
    /// more than once, so no de-duplication is performed.
    ///
    /// - Parameters:
    ///   - tracks: Tracks to add, in the order they should appear.
    ///   - transition: The transition to add them to.
    ///   - index: Insertion point within the transition's current order; `nil` appends.
    func addTracks(_ tracks: [Track], to transition: Transition, at index: Int? = nil) throws {
        var rows = transition.transitionTracks.sorted { $0.position < $1.position }

        let newRows = tracks.map { TransitionTrack(transition: transition, track: $0, position: 0) }
        for row in newRows { modelContext.insert(row) }

        Ordering.insert(newRows, at: index ?? rows.count, into: &rows)
        try modelContext.save()
    }

    /// Removes the given membership rows from `transition`, then renumbers the survivors so
    /// positions stay contiguous. Takes `TransitionTrack`s (not `Track`s) because a transition
    /// may contain the same track more than once — the row identifies the exact occurrence to
    /// remove. The removed rows' tracks are left untouched in the library.
    ///
    /// - Parameters:
    ///   - transitionTracks: The membership rows to remove.
    ///   - transition: The transition to remove them from.
    func removeTracks(_ transitionTracks: [TransitionTrack], from transition: Transition) throws {
        let removing = Set(transitionTracks.map(\.id))
        for row in transitionTracks {
            modelContext.delete(row)
        }

        let remaining = transition.transitionTracks
            .filter { !removing.contains($0.id) }
            .sorted { $0.position < $1.position }
        Ordering.reindex(remaining)
        try modelContext.save()
    }

    /// Moves the row at `source` to `destination` within `transition`, then renumbers so
    /// positions stay contiguous. `destination` follows the SwiftUI `onMove` convention
    /// (the offset to insert *before*, `0...count`). Indices are into the transition's rows
    /// in their current position order.
    ///
    /// - Parameters:
    ///   - transition: The transition whose rows are being reordered.
    ///   - source: Index of the row to move (`0..<count`).
    ///   - destination: Where to move it (`0...count`).
    func moveTrack(in transition: Transition, from source: Int, to destination: Int) throws {
        var rows = transition.transitionTracks.sorted { $0.position < $1.position }
        Ordering.move(&rows, from: source, to: destination)
        try modelContext.save()
    }
}
