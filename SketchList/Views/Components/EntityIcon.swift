//
//  EntityIcon.swift
//  SketchList
//
//  The three entity marks — Setlist, Playlist, Transition.
//
//  A mix of stock and drawn. Setlist and Playlist lean on the oldest convention
//  there is for the distinction that matters here: a **numbered** list is
//  ordered, a **bulleted** list is not. Setlist takes SF Symbols' `list.number`;
//  Playlist is drawn with square bullets so the two read as a matched pair
//  saying `<ol>` against `<ul>`. Transition has no stock equivalent — two bars
//  staggered in time is the mix itself.
//
//  Drawn marks are axis-aligned rectangles on a 24-unit grid, which is about as
//  Marquee as an icon gets. The one hard rule is weight: a thin stroke beside
//  800-weight display type reads as weak (UI_DESIGN.md § Stock SF Symbols).
//

import SwiftUI

struct EntityIcon: View {
    enum Kind {
        /// Numbered list — ordering is the whole point. Stock `list.number`.
        case setlist

        /// Bulleted list — a pool, no order implied.
        case playlist

        /// Two bars staggered in time.
        ///
        /// Provisional. UI_DESIGN.md § Still open records that this one hasn't
        /// landed; swapping it means editing this case and nothing else.
        case transition
    }

    let kind: Kind
    var size: CGFloat = 26

    var body: some View {
        Group {
            if let symbol = kind.systemImage {
                Image(systemName: symbol)
                    // Optically matched to the drawn marks, which fill about
                    // two-thirds of their box. Nudge if it reads large or small.
                    .font(.system(size: size * 0.86, weight: .heavy))
            } else {
                Canvas { context, canvasSize in
                    let unit = canvasSize.width / Self.grid
                    for bar in kind.bars {
                        let rect = CGRect(x: bar.x * unit,
                                          y: bar.y * unit,
                                          width: bar.width * unit,
                                          height: bar.height * unit)
                        context.fill(Path(rect), with: .style(.foreground))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true) // the button's own label carries the meaning
    }

    private static let grid: CGFloat = 24
}

// MARK: - Geometry

private struct Bar {
    let x, y, width, height: CGFloat
}

private extension EntityIcon.Kind {
    /// Non-nil when this mark is a stock symbol rather than a drawn one.
    var systemImage: String? {
        switch self {
        case .setlist: "list.number"
        default: nil
        }
    }

    var bars: [Bar] {
        switch self {
        case .setlist:
            [] // drawn from a stock symbol instead

        case .playlist:
            [
                Bar(x: 1, y: 4, width: 4, height: 4),
                Bar(x: 8, y: 4.75, width: 15, height: 2.5),
                Bar(x: 1, y: 10, width: 4, height: 4),
                Bar(x: 8, y: 10.75, width: 15, height: 2.5),
                Bar(x: 1, y: 16, width: 4, height: 4),
                Bar(x: 8, y: 16.75, width: 15, height: 2.5),
            ]

        case .transition:
            // Two bars only. A third, half-opacity bar used to bridge the gap as
            // a "blend region" — it read as a grey smudge rather than as a mix,
            // and the stagger says overlap on its own.
            [
                Bar(x: 1, y: 6, width: 15, height: 4.5),
                Bar(x: 8, y: 13.5, width: 15, height: 4.5),
            ]
        }
    }
}

// MARK: - Preview

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
                ForEach([EntityIcon.Kind.setlist, .playlist, .transition], id: \.self) { kind in
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

extension EntityIcon.Kind: Hashable {}
