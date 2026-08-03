//
//  EntityRow.swift
//  SketchList
//
//  One setlist, playlist, or transition in a list.
//
//  Used in four places: Home's "Jump back in", and each of the Setlists,
//  Playlists and Transitions index screens. Not to be confused with a track row —
//  the editors list *tracks*, which is a different shape entirely.
//
//  Takes plain values rather than a model. That keeps SwiftData out of the
//  component, lets Previews run without a `ModelContainer`, and means the same
//  row can render something that isn't persisted yet.
//

import SwiftUI

struct EntityRow: View {
    /// The entity's identifier. Seeds the default artwork, so a rename leaves
    /// the artwork alone — see `DefaultArtwork`.
    let id: UUID

    let name: String
    let kind: EntityKind
    let trackCount: Int
    let updatedAt: Date

    /// Whether to show the type column. Redundant on an index screen, where the
    /// screen itself already says what everything is; earns its place on Home,
    /// where the three kinds are mixed together.
    var showsKind: Bool = true

    /// This entity's cover art, once it has been given one. When absent the row
    /// falls back to `DefaultArtwork` — every entity always has a cover.
    var image: Image?

    @State private var isHovering = false

    // MARK: Body

    var body: some View {
        HStack(spacing: Metrics.Space.loose) {
            leading

            Text(name)
                .textStyle(.title)
                .foregroundStyle(isHovering ? Color.appAccent : Color.appInk)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: Metrics.Space.regular)

            if showsKind {
                Text(kind.displayName)
                    .textStyle(.label)
                    .foregroundStyle(.appInkFaint)
            }

            Text("\(trackCount) · \(updatedAt.editedDescription())")
                .textStyle(.numeric)
                .foregroundStyle(.appInkDim)
                .frame(width: Metrics.Row.recencyWidth, alignment: .trailing)
        }
        .frame(height: Metrics.Row.entity)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(name), \(kind.displayName)"))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    // MARK: Pieces

    /// Cover art. Deliberately does not respond to hover: once a row carries a
    /// real uploaded image the square is a photograph and cannot be recolored,
    /// so the default has to behave like an image too or the hover breaks the
    /// first time someone sets real artwork.
    @ViewBuilder
    private var leading: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                let palette = DefaultArtwork.palette(seed: id.uuidString)
                Rectangle()
                    .fill(palette.square)
                    .overlay {
                        EntityIcon(kind: kind, size: Metrics.Row.artworkGlyph)
                            .foregroundStyle(palette.ink)
                    }
            }
        }
        .frame(width: Metrics.Row.artwork, height: Metrics.Row.artwork)
        .clipped()
    }

    private var accessibilityValue: String {
        let tracks = trackCount == 1 ? "1 track" : "\(trackCount) tracks"
        return "\(tracks), edited \(updatedAt.editedDescription())"
    }
}

// MARK: - Preview

#Preview("Jump back in — mixed kinds") {
    VStack(alignment: .leading, spacing: 0) {
        HStack {
            Text("Jump back in")
            Spacer()
            Text("Last edited")
        }
        .textStyle(.label)
        .foregroundStyle(.appInkFaint)
        .padding(.bottom, Metrics.Space.snug)

        SampleRows(showsKind: true)
    }
    .padding(Metrics.Space.screen)
    .frame(width: 860)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("Index screen — one kind") {
    VStack(alignment: .leading, spacing: 0) {
        Text("Setlists")
            .textStyle(.label)
            .foregroundStyle(.appInkFaint)
            .padding(.bottom, Metrics.Space.snug)

        SampleRows(showsKind: false)
    }
    .padding(Metrics.Space.screen)
    .frame(width: 860)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

/// A stable, readable identifier for Previews — real entities supply their own.
private func previewIdentifier(_ number: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number)) ?? UUID()
}

private struct SampleRows: View {
    let showsKind: Bool

    private static let sample: [(String, EntityKind, Int, TimeInterval)] = [
        ("Warehouse Closing", .setlist, 18, -2 * 3600),
        ("Rolling & Percussive", .playlist, 64, -26 * 3600),
        ("Nightdrive → Pulse Width", .transition, 2, -3 * 86400),
        ("Sunday Rooftop", .setlist, 22, -16 * 86400),
        ("A Setlist With A Deliberately Overlong Name That Has To Truncate",
         .setlist, 7, -19 * 86400),
    ]

    var body: some View {
        let now = Date.now
        ForEach(Array(Self.sample.enumerated()), id: \.offset) { position, item in
            EntityRow(id: previewIdentifier(position + 1),
                      name: item.0,
                      kind: item.1,
                      trackCount: item.2,
                      updatedAt: now.addingTimeInterval(item.3),
                      showsKind: showsKind)
            Divider().overlay(Color.appRule)
        }
    }
}
