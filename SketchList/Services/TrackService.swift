//
//  TrackService.swift
//  SketchList
//
//  Write-path for the library aggregate (Track + Artist + TrackArtist). This is the
//  single place tracks enter, change, or leave the library, so the invariants the
//  store can't express (artist dedup, one credit per pair, …) live here. Import and
//  the eventual UI both go through this service rather than touching the context.
//

import Foundation
import SwiftData

enum TrackServiceError: Error, Equatable, CustomStringConvertible {
    /// A track must be credited to at least one artist.
    case noArtists

    var description: String {
        switch self {
        case .noArtists: "A track must have at least one artist."
        }
    }
}

@MainActor
final class TrackService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Adds a new track to the library, resolving and linking its artists.
    ///
    /// A new `Track` is always created — the library has no track-level uniqueness, so
    /// remixes and repeats are allowed. Each artist name is resolved via find-or-create:
    /// the name is trimmed, blanks are skipped, and an existing `Artist` with that name
    /// is reused rather than duplicated (otherwise a new one is made). A `TrackArtist`
    /// credit is created for each resolved artist, and everything is persisted in a
    /// single save. At least one non-blank artist is required.
    ///
    /// Artist matching is **case-insensitive** and whitespace-trimmed: "Illenium",
    /// "illenium", and " Illenium " all resolve to the same `Artist`, so artists aren't
    /// duplicated across casings and a track never receives the same credit twice. The
    /// casing of the first-created artist is preserved as the stored name.
    ///
    /// - Parameters:
    ///   - title: The track title.
    ///   - artists: Artist names to credit. Trimmed; blanks ignored; deduped case-insensitively.
    ///   - bpm: Beats per minute.
    ///   - key: Camelot key.
    ///   - duration: Length in whole seconds.
    ///   - spotifyID: Optional; reserved for the v2 Spotify integration.
    ///   - notes: Optional user notes.
    /// - Returns: The newly created `Track`.
    /// - Throws: `TrackServiceError.noArtists` if `artists` contains no non-blank name.
    @discardableResult
    func insert(
        title: String,
        artists: Set<String>,
        bpm: Double,
        key: CamelotKey,
        duration: Int,
        spotifyID: String? = nil,
        notes: String? = nil
    ) throws -> Track {
        guard artists.contains(where: { !Artist.normalize($0).isEmpty }) else {
            throw TrackServiceError.noArtists
        }

        let track = Track(title: title, bpm: bpm, key: key, duration: duration, spotifyID: spotifyID, notes: notes)
        modelContext.insert(track)
        try linkArtists(artists, to: track)

        try modelContext.save()
        return track
    }

    /// Creates a `TrackArtist` credit on `track` for each distinct artist name, reusing
    /// existing `Artist` rows. Matching is case-insensitive and whitespace-trimmed via
    /// `Artist.normalize(_:)`, resolved against the indexed `Artist.normalizedName`.
    private func linkArtists(_ names: Set<String>, to track: Track) throws {
        var processed = Set<String>()
        for rawName in names {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            let key = Artist.normalize(name)
            // Skip casing/whitespace variants of a name already handled this call — this
            // also guarantees one credit per artist (no duplicate TrackArtist rows), and
            // means we never look up a key we just created before the save.
            guard processed.insert(key).inserted else { continue }

            let artist: Artist
            if let existing = try findArtist(normalizedName: key) {
                artist = existing
            } else {
                artist = Artist(name: name)
                modelContext.insert(artist)
            }
            modelContext.insert(TrackArtist(track: track, artist: artist))
        }
    }

    /// Returns the single `Artist` whose `normalizedName` matches, or `nil`.
    private func findArtist(normalizedName key: String) throws -> Artist? {
        var descriptor = FetchDescriptor<Artist>(predicate: #Predicate { $0.normalizedName == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Updates a track's fields and reconciles its artist credits.
    ///
    /// A **full replacement**: the track is set to exactly the given values, and its
    /// artists become exactly `artists`. Artists are diffed against the current credits —
    /// newly listed artists are find-or-created and credited, dropped artists have their
    /// credit removed, and unchanged ones are left alone. Any artist left with no
    /// remaining credits is pruned. `updatedAt` is bumped. Matching is case-insensitive
    /// (see `insert`).
    ///
    /// - Parameters:
    ///   - track: The track to update.
    ///   - title: New title.
    ///   - artists: The complete new set of artist names (trimmed; blanks ignored).
    ///   - bpm: New BPM.
    ///   - key: New Camelot key.
    ///   - duration: New length in whole seconds.
    ///   - spotifyID: New Spotify id, or `nil` to clear it.
    ///   - notes: New notes, or `nil` to clear them.
    /// - Throws: `TrackServiceError.noArtists` if `artists` contains no non-blank name.
    func update(
        _ track: Track,
        title: String,
        artists: Set<String>,
        bpm: Double,
        key: CamelotKey,
        duration: Int,
        spotifyID: String? = nil,
        notes: String? = nil
    ) throws {
        guard artists.contains(where: { !Artist.normalize($0).isEmpty }) else {
            throw TrackServiceError.noArtists
        }

        track.title = title
        track.bpm = bpm
        track.key = key
        track.duration = duration
        track.spotifyID = spotifyID
        track.notes = notes
        track.updatedAt = .now

        let orphanCandidates = try reconcileArtists(artists, on: track)
        try modelContext.save()

        // Prune after saving so each artist's relationship reflects the removed credits.
        pruneOrphans(orphanCandidates)
        try modelContext.save()
    }

    /// Diffs `track`'s current credits against `names`: adds credits for newly listed
    /// artists (find-or-create), removes credits for dropped ones, leaves shared ones
    /// untouched. Returns the artists whose credit was removed — candidates for pruning.
    private func reconcileArtists(_ names: Set<String>, on track: Track) throws -> [Artist] {
        // Desired: normalized key -> first-seen display casing.
        var desired: [String: String] = [:]
        for rawName in names {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let key = Artist.normalize(name)
            if desired[key] == nil {
                desired[key] = name
            }
        }

        // Current credits keyed by the artist's normalized name.
        var current: [String: TrackArtist] = [:]
        for credit in track.trackArtists {
            guard let artist = credit.artist else { continue }
            current[artist.normalizedName] = credit
        }

        // Remove credits for artists no longer desired.
        var removedArtists: [Artist] = []
        for (key, credit) in current where desired[key] == nil {
            if let artist = credit.artist {
                removedArtists.append(artist)
            }
            modelContext.delete(credit)
        }

        // Add credits for newly desired artists.
        for (key, displayName) in desired where current[key] == nil {
            let artist: Artist
            if let existing = try findArtist(normalizedName: key) {
                artist = existing
            } else {
                artist = Artist(name: displayName)
                modelContext.insert(artist)
            }
            modelContext.insert(TrackArtist(track: track, artist: artist))
        }

        return removedArtists
    }

    /// Deletes any of `artists` that now have no remaining track credits. Call *after*
    /// saving the credit removals, so each artist's `trackArtists` reflects reality.
    private func pruneOrphans(_ artists: [Artist]) {
        for artist in artists where artist.trackArtists.isEmpty {
            modelContext.delete(artist)
        }
    }

    /// Removes a track from the library, pruning any artist left with no other tracks.
    ///
    /// The store cascades from `Track`, so deleting it also removes the track's
    /// `TrackArtist` credits and any setlist / playlist / transition join rows that
    /// reference it (mirroring the schema's `ON DELETE CASCADE` on `track_id`). After the
    /// cascade, any artist that was credited only on this track is now orphaned and pruned.
    func delete(_ track: Track) throws {
        let affectedArtists = track.trackArtists.compactMap(\.artist)
        modelContext.delete(track)
        try modelContext.save() // cascade removes this track's credits

        pruneOrphans(affectedArtists)
        try modelContext.save()
    }
}
