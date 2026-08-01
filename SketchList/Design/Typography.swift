//
//  Typography.swift
//  SketchList
//
//  The type scale. SwiftUI splits what designers think of as one "style" across
//  three separate modifiers — font, tracking, and casing — so `TextStyle` bundles
//  them and `.textStyle(_:)` applies all three at once. View code then never
//  contains a raw point size or tracking value.
//
//  The direction leans on two voices in opposition: a heavy, tightly-tracked
//  grotesk shouting in uppercase, and a small monospace speaking quietly in
//  wide-tracked caps. Nearly everything is one or the other.
//

import SwiftUI

// MARK: - TextStyle

/// A complete type treatment: face, size, weight, letter spacing, and casing.
struct TextStyle {
    let font: Font
    let tracking: CGFloat
    let textCase: Text.Case?

    init(font: Font, tracking: CGFloat = 0, textCase: Text.Case? = nil) {
        self.font = font
        self.tracking = tracking
        self.textCase = textCase
    }
}

// MARK: - The scale

extension TextStyle {
    // MARK: Display — the loud voice

    /// Hero type. Home's "What would you like to build?" and nothing else.
    static let hero = TextStyle(
        font: .system(size: 56, weight: .heavy),
        tracking: -3.1,
        textCase: .uppercase
    )

    /// Screen titles — a setlist's name at the top of its editor.
    static let display = TextStyle(
        font: .system(size: 34, weight: .heavy),
        tracking: -1.5,
        textCase: .uppercase
    )

    /// Subsection headings inside a screen.
    static let title = TextStyle(
        font: .system(size: 22, weight: .heavy),
        tracking: -0.9,
        textCase: .uppercase
    )

    /// A track or entity name in a list row. The workhorse.
    static let rowTitle = TextStyle(
        font: .system(size: 15, weight: .heavy),
        tracking: -0.45,
        textCase: .uppercase
    )

    // MARK: Mono — the quiet voice

    /// Section labels and column headers: wide-tracked, small, deliberately faint.
    static let label = TextStyle(
        font: .system(size: 9.5, weight: .regular, design: .monospaced),
        tracking: 1.9,
        textCase: .uppercase
    )

    /// Metadata beneath a row title — artist, BPM, duration.
    static let meta = TextStyle(
        font: .system(size: 11, weight: .regular, design: .monospaced),
        tracking: 0
    )

    /// Numeric readouts that must align in a column: BPM, scores, timecodes.
    static let numeric = TextStyle(
        font: .system(size: 12, weight: .regular, design: .monospaced).monospacedDigit(),
        tracking: 0
    )

    /// Descriptions and longer prose. The only style that isn't shouting or
    /// whispering — used sparingly, since the direction has little room for it.
    static let body = TextStyle(
        font: .system(size: 13, weight: .regular),
        tracking: 0
    )

    // MARK: Numerals

    /// Setlist position numbers, promoted to a design element: large, tabular,
    /// and dim until the row is selected.
    static let positionNumeral = TextStyle(
        font: .system(size: 26, weight: .heavy).monospacedDigit(),
        tracking: -1.6
    )
}

// MARK: - Application

extension View {
    /// Applies a `TextStyle`'s font, tracking, and casing together.
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .textCase(style.textCase)
    }
}

// MARK: - Preview

#Preview("Type scale") {
    VStack(alignment: .leading, spacing: 18) {
        Text("What would you like to build?").textStyle(.hero)
        Text("Warehouse Closing").textStyle(.display)
        Text("Jump back in").textStyle(.title)
        Text("Nightdrive").textStyle(.rowTitle)
        Text("Compatible with 06").textStyle(.label).foregroundStyle(.appInkFaint)
        Text("Kolter · 124.0 BPM").textStyle(.meta).foregroundStyle(.appInkDim)
        Text("128.5").textStyle(.numeric).foregroundStyle(.appInkDim)
        Text("Slow burn into the 5am stretch.").textStyle(.body).foregroundStyle(.appInkDim)
        Text("06").textStyle(.positionNumeral).foregroundStyle(.appAccent)
    }
    .foregroundStyle(.appInk)
    .padding(40)
    .frame(width: 720, alignment: .leading)
    .background(Color.appBackground)
}
