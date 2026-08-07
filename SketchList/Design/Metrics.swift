//
//  Metrics.swift
//  SketchList
//
//  Spacing, sizing, and line weights. Same rationale as the color and type
//  tokens: view code should never contain a bare number whose meaning has to be
//  inferred from context.
//

import CoreGraphics

/// Layout constants for the app.
enum Metrics {
    // MARK: Spacing

    /// A 2pt base step, with 4pt as the usual increment. Keeping the base at 2
    /// rather than 4 leaves room for the odd value that is genuinely chosen by
    /// eye — `seam` is the current example — without it becoming a special case
    /// sitting off the grid.
    enum Space {
        static let hair: CGFloat = 2
        static let tight: CGFloat = 4

        /// The gap between blocks that belong to one group — the three creation
        /// buttons on Home. Narrow enough that the row reads as a single object
        /// made of parts, wide enough that two adjacent 2pt rules don't fuse
        /// into one thick line.
        static let seam: CGFloat = 6

        static let snug: CGFloat = 8
        static let regular: CGFloat = 12
        static let roomy: CGFloat = 16
        static let loose: CGFloat = 24
        static let section: CGFloat = 32
        static let screen: CGFloat = 40
    }

    // MARK: Strokes

    enum Stroke {
        /// Hairline separators between rows.
        static let hairline: CGFloat = 1

        /// The outline around a bordered block — the creation buttons on Home.
        /// Heavy enough to hold its own against 800-weight type; a hairline here
        /// reads as weak beside the display face.
        static let rule: CGFloat = 2

        /// The selection marker running down the leading edge of a selected row.
        static let selection: CGFloat = 3
    }

    // MARK: Rows

    enum Row {
        /// A track row in a setlist, playlist, or transition.
        static let track: CGFloat = 52

        /// A setlist / playlist / transition row in a list or on Home.
        /// Sized around the artwork thumbnail plus its breathing room.
        static let entity: CGFloat = 64

        /// The cover art leading an entity row.
        static let artwork: CGFloat = 36

        /// The entity mark drawn inside default artwork, sized to leave the
        /// square a visible margin rather than filling it edge to edge.
        static let artworkGlyph: CGFloat = 22

        /// Width reserved for the trailing "18 · 2h ago" column, so the counts
        /// and dates line up down the list regardless of digit count.
        static let recencyWidth: CGFloat = 124

        /// A compact row in the right-hand library pane.
        static let library: CGFloat = 44

        /// A sidebar destination. Shorter than any content row because the
        /// sidebar is set in the 11pt mono voice, not the display face — a
        /// 44pt row around 11pt type reads as padding rather than as a list.
        static let nav: CGFloat = 32

        /// Width reserved for the position numeral column.
        static let numeralWidth: CGFloat = 44

        /// Width reserved for a right-aligned BPM column, so columns line up
        /// across rows regardless of digit count.
        static let bpmWidth: CGFloat = 52
    }

    // MARK: Panes

    enum Pane {
        static let sidebarMin: CGFloat = 190
        static let sidebarIdeal: CGFloat = 210
        static let sidebarMax: CGFloat = 280

        /// The contextual right-hand library pane in the editors.
        static let inspector: CGFloat = 320

        /// Below this the right pane collapses rather than being squeezed.
        static let contentMin: CGFloat = 520
    }

    // MARK: Controls

    enum Control {
        /// Corner radius. Marquee is hard-edged by design — this exists so the
        /// value has one home if that ever changes, not because it varies.
        static let radius: CGFloat = 0

        static let chipMinWidth: CGFloat = 46
        static let chipVerticalPadding: CGFloat = 4
        static let chipHorizontalPadding: CGFloat = 8
    }
}
