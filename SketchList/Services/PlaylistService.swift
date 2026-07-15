//
//  PlaylistService.swift
//  SketchList
//

import Foundation
import SwiftData

enum PlaylistServiceError: Error, Equatable, CustomStringConvertible {
    case duplicateName(String)
    case blankName

    var description: String {
        switch self {
        case let .duplicateName(name): "A playlist named \"\(name)\" already exists."
        case .blankName: "A playlist must have a non-empty name."
        }
    }
}

@MainActor
final class PlaylistService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns the playlist whose `name` exactly matches, or `nil`. Backs the
    /// "no duplicate playlist names" rule.
    private func findPlaylist(name: String) throws -> Playlist? {
        var descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Creates a new playlist. The name is trimmed of surrounding whitespace and must be
    /// non-empty and unique within playlists (case-sensitive; names may be reused across
    /// setlists/transitions).
    ///
    /// - Parameters:
    ///   - name: Display name. Trimmed; must be non-empty and not duplicate an existing playlist.
    ///   - descriptionText: Optional description of the playlist's purpose.
    ///   - notes: Optional longer working notes.
    /// - Returns: The newly created `Playlist`.
    /// - Throws: `PlaylistServiceError.blankName` if the trimmed name is empty;
    ///   `.duplicateName` if a playlist with that name already exists.
    @discardableResult
    func insert(name: String, descriptionText: String?, notes: String?) throws -> Playlist {
        guard let name = name.trimmedNonEmpty else { throw PlaylistServiceError.blankName }
        guard try findPlaylist(name: name) == nil else { throw PlaylistServiceError.duplicateName(name) }

        let playlist = Playlist(name: name, descriptionText: descriptionText, notes: notes)
        modelContext.insert(playlist)

        try modelContext.save()
        return playlist
    }

    /// Updates a playlist's metadata (full replacement) and bumps `updatedAt`. The name is
    /// trimmed and must stay non-empty and unique within playlists — renaming a playlist to
    /// its own current name is allowed. Passing `nil` for `descriptionText`/`notes` clears
    /// the respective field.
    ///
    /// - Parameters:
    ///   - playlist: The playlist to update.
    ///   - name: New name. Trimmed; must be non-empty and not collide with another playlist.
    ///   - descriptionText: New description, or `nil` to clear it.
    ///   - notes: New notes, or `nil` to clear them.
    /// - Throws: `PlaylistServiceError.blankName` if the trimmed name is empty;
    ///   `.duplicateName` if another playlist already has that name.
    func update(_ playlist: Playlist, name: String, descriptionText: String? = nil, notes: String? = nil) throws {
        guard let name = name.trimmedNonEmpty else { throw PlaylistServiceError.blankName }
        if let existing = try findPlaylist(name: name), existing.id != playlist.id {
            throw PlaylistServiceError.duplicateName(name)
        }

        playlist.name = name
        playlist.descriptionText = descriptionText
        playlist.notes = notes
        playlist.updatedAt = .now
        try modelContext.save()
    }

    /// Deletes a playlist. Its `PlaylistTrack` rows are removed by the store cascade; the
    /// referenced tracks are left untouched in the library.
    func delete(_ playlist: Playlist) throws {
        modelContext.delete(playlist)
        try modelContext.save()
    }
}
