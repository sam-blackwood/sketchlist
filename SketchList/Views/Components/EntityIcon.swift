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
    /// How much ink the mark carries.
    ///
    /// Not decoration — it exists so the mark can match the type it sits beside.
    /// `.heavy` was drawn for the 22pt/800 creation buttons, where a hairline
    /// icon looks weak. The sidebar sets 11pt monospace, and beside that the
    /// same rule inverts: a heavy mark out-weighs the word it is labelling. The
    /// "icons must be heavy" line in UI_DESIGN.md is about the display voice
    /// specifically, not a global rule.
    enum Weight {
        case heavy, light

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
        Group {
            if let symbol = kind.systemImage {
                Image(systemName: symbol)
                    // Optically matched to the drawn marks, which fill about
                    // two-thirds of their box. Nudge if it reads large or small.
                    .font(.system(size: size * 0.86, weight: weight.symbolWeight))
            } else {
                Canvas { context, canvasSize in
                    let unit = canvasSize.width / Self.grid
                    for bar in kind.bars(weight) {
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

private extension EntityKind {
    /// Non-nil when this mark is a stock symbol rather than a drawn one.
    var systemImage: String? {
        switch self {
        case .setlist: "list.number"
        default: nil
        }
    }

    /// Geometry per weight — not one shape scaled.
    ///
    /// The light marks are drawn thinner rather than smaller. A 24-unit grid at
    /// a 13pt icon puts one unit at 0.54pt, so the heavy bars' 2.5 units would
    /// land near 1.35pt and the earlier 1.5-unit attempt at 0.81pt — thicknesses
    /// that antialias into a gray smudge instead of an edge. Every light bar
    /// here is 2 units, or 1.08pt at 13pt, which stays crisp. Hard edges are the
    /// point of this whole direction; a blurry mark is worse than no mark.
    func bars(_ weight: EntityIcon.Weight) -> [Bar] {
        switch self {
        case .setlist:
            // Numbered list — ordering is the whole point. Stock `list.number`,
            // so there is nothing to draw here at any weight.
            []

        case .playlist:
            // Bulleted list — a pool, no order implied. Paired with Setlist's
            // numerals this states `<ul>` against `<ol>`.
            switch weight {
            case .heavy:
                [
                    Bar(x: 1, y: 4, width: 4, height: 4),
                    Bar(x: 8, y: 4.75, width: 15, height: 2.5),
                    Bar(x: 1, y: 10, width: 4, height: 4),
                    Bar(x: 8, y: 10.75, width: 15, height: 2.5),
                    Bar(x: 1, y: 16, width: 4, height: 4),
                    Bar(x: 8, y: 16.75, width: 15, height: 2.5),
                ]
            case .light:
                [
                    Bar(x: 1, y: 4, width: 3, height: 3),
                    Bar(x: 8, y: 4.5, width: 15, height: 2),
                    Bar(x: 1, y: 11, width: 3, height: 3),
                    Bar(x: 8, y: 11.5, width: 15, height: 2),
                    Bar(x: 1, y: 18, width: 3, height: 3),
                    Bar(x: 8, y: 18.5, width: 15, height: 2),
                ]
            }

        case .transition:
            // Two bars only. A third, half-opacity bar used to bridge the gap as
            // a "blend region" — it read as a gray smudge rather than as a mix,
            // and the stagger says overlap on its own.
            switch weight {
            case .heavy:
                [
                    Bar(x: 1, y: 6, width: 15, height: 4.5),
                    Bar(x: 8, y: 13.5, width: 15, height: 4.5),
                ]
            case .light:
                [
                    Bar(x: 1, y: 7, width: 15, height: 2.5),
                    Bar(x: 8, y: 14.5, width: 15, height: 2.5),
                ]
            }
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

