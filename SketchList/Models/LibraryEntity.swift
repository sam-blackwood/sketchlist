//
//  LibraryEntity.swift
//  SketchList
//
//  One of the three container types, wrapped so a mixed list can hold all of
//  them.
//
//  Home's "Jump back in" shows setlists, playlists and transitions together,
//  ordered by when they were last edited. Those are three unrelated `@Model`
//  types, so they cannot share an array without something like this.
//
//  A wrapper rather than a flattened struct of name/count/date: the row has to
//  be able to *open* what was clicked, and an enum carries the real object
//  through. Copying the fields out would mean looking the original back up by
//  id and kind afterwards, which is work to undo work.
//

import Foundation

enum LibraryEntity: Identifiable {
    case setlist(Setlist)
    case playlist(Playlist)
    case transition(Transition)

    var id: UUID {
        switch self {
        case let .setlist(setlist): setlist.id
        case let .playlist(playlist): playlist.id
        case let .transition(transition): transition.id
        }
    }

    var kind: EntityKind {
        switch self {
        case .setlist: .setlist
        case .playlist: .playlist
        case .transition: .transition
        }
    }

    var name: String {
        switch self {
        case let .setlist(setlist): setlist.name
        case let .playlist(playlist): playlist.name
        case let .transition(transition): transition.name
        }
    }

    var updatedAt: Date {
        switch self {
        case let .setlist(setlist): setlist.updatedAt
        case let .playlist(playlist): playlist.updatedAt
        case let .transition(transition): transition.updatedAt
        }
    }

    var trackCount: Int {
        switch self {
        case let .setlist(setlist): setlist.setlistTracks.count
        case let .playlist(playlist): playlist.playlistTracks.count
        case let .transition(transition): transition.transitionTracks.count
        }
    }

    /// Cover art filename, when this kind has one.
    ///
    /// Transitions have no artwork column — whether they get cover art at all is
    /// still undecided (UI_DESIGN.md § Custom Cover Art), so they always fall
    /// back to the generated default.
    var artworkFilename: String? {
        switch self {
        case let .setlist(setlist): setlist.artworkFilename
        case let .playlist(playlist): playlist.artworkFilename
        case .transition: nil
        }
    }
}

// MARK: - Equality

extension LibraryEntity: Hashable {
    // Identity, not contents: two wrappers around the same object are the same
    // entity even if a field changed between reads. Kind is included because
    // ids are per-table UUIDs and nothing stops two tables colliding.
    static func == (lhs: LibraryEntity, rhs: LibraryEntity) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(kind)
    }
}
