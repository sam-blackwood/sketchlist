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
}
