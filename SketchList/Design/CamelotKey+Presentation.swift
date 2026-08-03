//
//  CamelotKey+Presentation.swift
//  SketchList
//
//  How a Camelot key looks. Purely presentational — compatibility rules live in
//  the model and services layer (see `CamelotKey.isCompatible` and
//  SYSTEM_DESIGN.md § Compatibility primitive) and are deliberately not
//  duplicated here.
//

import SwiftUI

// MARK: - Color

extension CamelotKey {
    /// Hue in degrees for this key's wheel position.
    ///
    /// The Camelot wheel divides harmony into twelve 30° segments, so each step
    /// maps to exactly 30° of hue. That makes the mapping a genuine bijection —
    /// keys a step apart are a step apart in color, and the wheel closes
    /// cleanly at 12 → 1 rather than accumulating drift.
    ///
    /// The 152° origin puts 1A/1B in green and lands 8A (the most common key in
    /// four-to-the-floor dance music) in magenta, which keeps the colors most
    /// often on screen well separated.
    var hueDegrees: Double {
        (152 - Double(number - 1) * 30).truncatingRemainder(dividingBy: 360)
            .nonNegativeDegrees
    }

    /// Foreground color for the key's text in a chip.
    ///
    /// Minor (A) keys sit slightly deeper than their major (B) counterparts, so a
    /// glance distinguishes 8A from 8B without reading the letter.
    var inkColor: Color {
        Color(hue: hueDegrees / 360,
              saturation: isMinor ? 0.62 : 0.52,
              brightness: isMinor ? 0.72 : 0.82)
    }

    /// Border color for the key's chip — the same hue, dropped well back so the
    /// chip reads as an outline rather than a filled badge.
    var strokeColor: Color {
        Color(hue: hueDegrees / 360,
              saturation: isMinor ? 0.48 : 0.40,
              brightness: isMinor ? 0.34 : 0.38)
    }

    /// A solid fill of the key's hue, for spectrum bars and set fingerprints.
    var fillColor: Color {
        Color(hue: hueDegrees / 360,
              saturation: isMinor ? 0.58 : 0.48,
              brightness: isMinor ? 0.56 : 0.66)
    }
}

// MARK: - Text

extension CamelotKey {
    /// The key as shown in the interface, e.g. "8A".
    var displayName: String { rawValue }

    /// Long form for accessibility labels and tooltips, e.g. "8A, minor".
    var accessibilityDescription: String {
        "\(rawValue), \(isMinor ? "minor" : "major")"
    }
}

// MARK: - Helpers

private extension Double {
    /// Normalizes a possibly-negative degree value into 0..<360.
    var nonNegativeDegrees: Double { self < 0 ? self + 360 : self }
}
