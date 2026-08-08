//
//  EntityIcon.swift
//  SketchList
//
//  The three entity marks — Setlist, Playlist, Transition.
//
//  All three are stock SF Symbols sharing one skeleton: three horizontal rows.
//  That is what makes them read as a set rather than as three unrelated marks.
//
//    Setlist      list.number          numbered rows — order is the point
//    Playlist     list.bullet          bulleted rows — a pool, no order implied
//    Transition   slider.horizontal.3  faders — the act of moving between tracks
//
//  Setlist and Playlist are the oldest convention there is for ordered against
//  unordered, and Apple draws them as a matched pair. Transition has no literal
//  equivalent; faders were chosen over a drawn mark because they carry the same
//  three-row structure, and moving faders is what a transition physically *is*
//  to a DJ.
//
//  What was given up: the previous drawn mark — two bars staggered in time —
//  encoded the data model exactly, since a Transition record is tracks that
//  overlap. Faders say "mixing" instead. It is in the file's history if the
//  trade turns out badly.
//
//  `Weight` exists because the rule about icon weight is contextual, not
//  absolute: a thin stroke beside 800-weight display type reads as weak, while a
//  heavy one beside 11pt monospace out-weighs the word it labels
//  (UI_DESIGN.md § Stock SF Symbols).
//

import SwiftUI

struct EntityIcon: View {
    /// How much ink the mark carries, so it can match the type beside it.
    enum Weight {
        /// For the display voice — the 22pt/800 creation buttons.
        case heavy
        /// For the mono voice — 11pt sidebar destinations.
        case light

        var symbolWeight: Font.Weight {
            switch self {
            case .heavy: .heavy
            case .light: .regular
            }
        }
    }

    let kind: EntityKind
    var size: CGFloat = 26
    var weight: Weight = .heavy

    var body: some View {
        Image(systemName: kind.systemImage)
            // Symbols carry internal padding, so they render a little smaller
            // than their nominal point size. Nudge if a mark reads large or
            // small against its label.
            .font(.system(size: size * 0.86, weight: weight.symbolWeight))
            .frame(width: size, height: size)
            .accessibilityHidden(true) // the row or button label carries the meaning
    }
}

// MARK: - Marks

extension EntityKind {
    var systemImage: String {
        switch self {
        case .setlist: "list.number"
        case .playlist: "list.bullet"
        case .transition: "slider.horizontal.3"
        }
    }
}

// MARK: - Previews

#Preview("Entity icons") {
    VStack(alignment: .leading, spacing: Metrics.Space.loose) {
        HStack(spacing: Metrics.Space.loose) {
            ForEach(["Setlist", "Playlist", "Transition"], id: \.self) { name in
                Text(name)
                    .textStyle(.label)
                    .foregroundStyle(.appInkFaint)
                    .frame(width: 90, alignment: .leading)
            }
        }
        ForEach([CGFloat(64), 26, 18, 14], id: \.self) { size in
            HStack(spacing: Metrics.Space.loose) {
                ForEach([EntityKind.setlist, .playlist, .transition], id: \.self) { kind in
                    EntityIcon(kind: kind, size: size)
                        .frame(width: 90, alignment: .leading)
                }
            }
        }
    }
    .foregroundStyle(.appInk)
    .padding(Metrics.Space.screen)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#if DEBUG

    #Preview("Family check — can you tell them apart at 11pt?") {
        // The whole question. All three now share a three-row skeleton, which is
        // what makes them a set — but `list.bullet` and `slider.horizontal.3`
        // are both "three rows with a small mark on each", and the sidebar shows
        // them two apart in the same list. If they blur together here, the
        // family has gone too far.
        VStack(alignment: .leading, spacing: Metrics.Space.section) {
            VStack(alignment: .leading, spacing: Metrics.Space.regular) {
                Text("Sidebar — true size, light weight")
                    .textStyle(.label)
                    .foregroundStyle(.appInkFaint)

                ForEach([EntityKind.setlist, .playlist, .transition], id: \.self) { kind in
                    HStack(spacing: Metrics.Space.regular) {
                        EntityIcon(kind: kind, size: TextStyle.nav.size, weight: .light)
                        Text(kind.pluralName)
                        Spacer(minLength: 0)
                    }
                    .textStyle(.nav)
                    .foregroundStyle(.appInkDim)
                    .frame(height: Metrics.Row.nav)
                }
            }

            VStack(alignment: .leading, spacing: Metrics.Space.regular) {
                Text("Enlarged — where the difference is obvious")
                    .textStyle(.label)
                    .foregroundStyle(.appInkFaint)

                HStack(spacing: Metrics.Space.section) {
                    ForEach([EntityKind.setlist, .playlist, .transition], id: \.self) { kind in
                        EntityIcon(kind: kind, size: 44, weight: .light)
                    }
                }
                .foregroundStyle(.appInk)
            }

            VStack(alignment: .leading, spacing: Metrics.Space.regular) {
                Text("Creation buttons — heavy weight")
                    .textStyle(.label)
                    .foregroundStyle(.appInkFaint)

                HStack(spacing: Metrics.Space.section) {
                    ForEach([EntityKind.setlist, .playlist, .transition], id: \.self) { kind in
                        EntityIcon(kind: kind, size: 22)
                    }
                }
                .foregroundStyle(.appInk)
            }
        }
        .padding(Metrics.Space.screen)
        .frame(width: 420, alignment: .leading)
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }

#endif
