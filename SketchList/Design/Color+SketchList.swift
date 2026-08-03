//
//  Color+SketchList.swift
//  SketchList
//
//  Color helpers.
//
//  The palette itself is NOT declared here. Xcode generates a `Color` symbol for
//  every set in Assets.xcassets (`AppAccent` → `Color.appAccent`), so declaring
//  them by hand is an invalid redeclaration. The catalog is the single source of
//  truth, which is exactly what UI_DESIGN.md § Themeable architecture asks for:
//  retheming means editing color values, not touching view code.
//
//  The vocabulary, for reference:
//
//    appBackground   window ground
//    appSurface      recessed plane — sidebar, secondary panes
//    appInk          primary text
//    appInkDim       secondary text — artists, metadata
//    appInkFaint     tertiary — section labels, units, disabled
//    appRule         hairline separators, never text
//    appAccent       the acid. One meaning only: active or selected
//    appOnAccent     text drawn on top of appAccent
//
//  Every set carries a dark slot (canonical) and a light slot (provisional —
//  Marquee is a dark-first direction and its light counterpart is not yet
//  designed; the slot exists so no code bakes in a dark-only assumption).
//

import SwiftUI

#if canImport(AppKit)
    import AppKit
#endif

// MARK: - Contrast

extension Color {
    /// Chooses black or white text for an arbitrary background using WCAG
    /// relative luminance.
    ///
    /// Unused while the accent is a fixed token, but the accent-picker experiment
    /// showed a user-chosen accent needs this: chartreuse and mint want black
    /// text, while ultramarine and signal red want white. Keeping the rule here
    /// means the answer never has to be guessed at a call site.
    static func readableInk(on background: Color) -> Color {
        background.relativeLuminance > 0.42 ? .black : .white
    }

    /// WCAG relative luminance, 0 (black) to 1 (white).
    var relativeLuminance: Double {
        #if canImport(AppKit)
            guard let srgb = NSColor(self).usingColorSpace(.sRGB) else { return 0 }
            let channels = [srgb.redComponent, srgb.greenComponent, srgb.blueComponent]
            let linear = channels.map { channel -> Double in
                channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        #else
            return 0
        #endif
    }
}
