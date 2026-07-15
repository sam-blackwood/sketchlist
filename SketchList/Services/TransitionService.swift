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
}
