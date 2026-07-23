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

    /// Adds `tracks` to `playlist`, in order, skipping any that are already present — a
    /// playlist holds each track at most once. Tracks already in the playlist, and repeats
    /// within `tracks` itself, are silently ignored (add-if-absent semantics, not an
    /// error). Surviving tracks are wrapped in `PlaylistTrack` rows, spliced in at `index`
    /// (or appended when `index` is `nil`), and all positions are renumbered.
    ///
    /// - Parameters:
    ///   - tracks: Tracks to add, in the order they should appear.
    ///   - playlist: The playlist to add them to.
    ///   - index: Insertion point within the playlist's current order; `nil` appends.
    /// - Returns: The rows actually created — compare `count` to `tracks.count` to see how
    ///   many were skipped as duplicates.
    @discardableResult
    func addTracks(_ tracks: [Track], to playlist: Playlist, at index: Int? = nil) throws -> [PlaylistTrack] {
        var rows = playlist.playlistTracks.sorted { $0.position < $1.position }

        // Seeded with tracks already in the playlist; `inserted == false` also catches
        // repeats within `tracks`, so each track is added at most once.
        var seen = Set(rows.compactMap { $0.track?.id })
        let newRows = tracks.compactMap { track -> PlaylistTrack? in
            guard seen.insert(track.id).inserted else { return nil }
            return PlaylistTrack(playlist: playlist, track: track, position: 0)
        }
        for row in newRows { modelContext.insert(row) }

        Ordering.insert(newRows, at: index ?? rows.count, into: &rows)
        try modelContext.save()
        return newRows
    }

    /// Removes the given membership rows from `playlist`, then renumbers the survivors so
    /// positions stay contiguous. The removed rows' tracks are left untouched in the library.
    ///
    /// - Parameters:
    ///   - playlistTracks: The membership rows to remove.
    ///   - playlist: The playlist to remove them from.
    func removeTracks(_ playlistTracks: [PlaylistTrack], from playlist: Playlist) throws {
        let removing = Set(playlistTracks.map(\.id))
        for row in playlistTracks {
            modelContext.delete(row)
        }

        let remaining = playlist.playlistTracks
            .filter { !removing.contains($0.id) }
            .sorted { $0.position < $1.position }
        Ordering.reindex(remaining)
        try modelContext.save()
    }

    /// Moves the row at `source` to `destination` within `playlist`, then renumbers so
    /// positions stay contiguous. `destination` follows the SwiftUI `onMove` convention
    /// (the offset to insert *before*, `0...count`). Indices are into the playlist's rows
    /// in their current position order.
    ///
    /// - Parameters:
    ///   - playlist: The playlist whose rows are being reordered.
    ///   - source: Index of the row to move (`0..<count`).
    ///   - destination: Where to move it (`0...count`).
    func moveTrack(in playlist: Playlist, from source: Int, to destination: Int) throws {
        var rows = playlist.playlistTracks.sorted { $0.position < $1.position }
        Ordering.move(&rows, from: source, to: destination)
        try modelContext.save()
    }
}
