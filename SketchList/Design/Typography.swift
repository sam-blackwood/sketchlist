//
//  Typography.swift
//  SketchList
//
//  The type scale. SwiftUI splits what designers think of as one "style" across
//  three separate modifiers — font, tracking, and casing — so `TextStyle`
//  bundles them and `.textStyle(_:)` applies all three at once. View code then
//  never contains a raw point size or tracking value.
//
//  A style stores its *components* rather than a finished `Font`, and derives
//  the font on demand. That matters because not everything can go through
//  `Text`: `OutlinedText` reaches into Core Text for glyph contours and needs
//  the same size, weight and tracking in AppKit terms. Storing the parts means
//  both paths read one source of truth instead of two sets of numbers drifting.
//
//  The direction leans on two voices in opposition: a heavy, tightly-tracked
//  grotesk shouting in uppercase, and a small monospace speaking quietly in
//  wide-tracked caps. Nearly everything is one or the other.
//
//  Changing a size: these are shared, so move one only when the *role* wants a
//  different size everywhere it appears. If a single screen wants something in
//  between, add a step rather than nudging an existing one — a token bent to
//  satisfy one call site stops being a scale.
//
//  The working display ladder is 15 / 22 / 34, stepping up by 1.47 then 1.55 —
//  steadily widening. That progression is the thing to preserve when adding to
//  or editing the scale; it is what keeps sizes feeling related rather than
//  arbitrary. (22 was briefly specified as 24, which would have made the
//  progression 1.60, 1.42 — lumpy. The doc was wrong, not the token.)
//
//  `hero` at 72 deliberately sits *outside* that ladder — 34 → 72 is a jump of
//  2.12, far wider than any other step. That is the point: it appears once, on
//  one screen, as a poster rather than as interface, and tying it to the UI
//  ladder would only make it smaller than the design calls for. Do not "fix"
//  the ratio by nudging it toward 56.
//

import SwiftUI

#if canImport(AppKit)
    import AppKit
#endif

// MARK: - TextStyle

/// A complete type treatment: face, size, weight, letter spacing, and casing.
struct TextStyle {
    let size: CGFloat
    let weight: Weight
    let design: Font.Design
    let tracking: CGFloat
    let textCase: Text.Case?
    let monospacedDigits: Bool

    init(
        size: CGFloat,
        weight: Weight = .regular,
        design: Font.Design = .default,
        tracking: CGFloat = 0,
        textCase: Text.Case? = nil,
        monospacedDigits: Bool = false
    ) {
        self.size = size
        self.weight = weight
        self.design = design
        self.tracking = tracking
        self.textCase = textCase
        self.monospacedDigits = monospacedDigits
    }

    /// The SwiftUI font for `Text`.
    var font: Font {
        let base = Font.system(size: size, weight: weight.swiftUI, design: design)
        return monospacedDigits ? base.monospacedDigit() : base
    }

    #if canImport(AppKit)
        /// The same face in AppKit terms, for anything that has to bypass `Text` —
        /// currently only `OutlinedText`, which needs glyph contours from Core Text.
        var appKitFont: NSFont {
            switch design {
            case .monospaced:
                NSFont.monospacedSystemFont(ofSize: size, weight: weight.appKit)
            default:
                NSFont.systemFont(ofSize: size, weight: weight.appKit)
            }
        }
    #endif

    /// Applies this style's casing to a raw string, for the same bypass case.
    func applyingCase(to string: String) -> String {
        switch textCase {
        case .uppercase: string.uppercased()
        case .lowercase: string.lowercased()
        default: string
        }
    }
}

// MARK: - Weight

extension TextStyle {
    /// Weights the app actually uses, carrying both framework spellings.
    ///
    /// `Font.Weight` and `NSFont.Weight` are unrelated types with no conversion
    /// between them, so a shared vocabulary is the only way to keep a style's
    /// filled and outlined renderings at the same weight.
    enum Weight {
        case regular, medium, semibold, bold, heavy, black

        var swiftUI: Font.Weight {
            switch self {
            case .regular: .regular
            case .medium: .medium
            case .semibold: .semibold
            case .bold: .bold
            case .heavy: .heavy
            case .black: .black
            }
        }

        #if canImport(AppKit)
            var appKit: NSFont.Weight {
                switch self {
                case .regular: .regular
                case .medium: .medium
                case .semibold: .semibold
                case .bold: .bold
                case .heavy: .heavy
                case .black: .black
                }
            }
        #endif
    }
}

// MARK: - The scale

extension TextStyle {
    // MARK: Display — the loud voice

    /// Hero type. Home's "What would you like to build?" and nothing else.
    /// Tracking is −0.055em, matching the prototype.
    static let hero = TextStyle(size: 72, weight: .heavy, tracking: -3.96, textCase: .uppercase)

    /// Screen titles — a setlist's name at the top of its editor.
    static let display = TextStyle(size: 34, weight: .heavy, tracking: -1.5, textCase: .uppercase)

    /// Subsection headings inside a screen, and creation-button titles.
    static let title = TextStyle(size: 22, weight: .heavy, tracking: -0.9, textCase: .uppercase)

    /// A track or entity name in a list row. The workhorse.
    static let rowTitle = TextStyle(size: 15, weight: .heavy, tracking: -0.45, textCase: .uppercase)

    // MARK: Mono — the quiet voice

    /// Section labels and column headers: wide-tracked, small, deliberately faint.
    static let label = TextStyle(size: 9.5, design: .monospaced, tracking: 1.9, textCase: .uppercase)

    /// Metadata beneath a row title — artist, BPM, duration.
    static let meta = TextStyle(size: 11, design: .monospaced)

    /// Sidebar destinations.
    ///
    /// 11pt because that is the size the mono voice already uses for *words* —
    /// `meta` is an artist name, while `numeric` at 12 carries monospaced digits
    /// and exists for figures. Sidebar labels are words, so this shares `meta`'s
    /// size rather than introducing a fourth mono step.
    ///
    /// Tracked and uppercased like `label`, but one size up, because the group
    /// headers above these rows *are* `label`: at a shared 9.5 the heading and
    /// the destination under it become indistinguishable and only color
    /// separates them. 13pt was rejected — it is `body`'s number in the other
    /// face, and reusing it would make "13" mean two unrelated things.
    static let nav = TextStyle(size: 11, design: .monospaced, tracking: 2, textCase: .uppercase)

    /// Numeric readouts that must align in a column: BPM, scores, timecodes.
    static let numeric = TextStyle(size: 12, design: .monospaced, monospacedDigits: true)

    /// Descriptions and longer prose. The only style that isn't shouting or
    /// whispering — used sparingly, since the direction has little room for it.
    static let body = TextStyle(size: 13)

    // MARK: Numerals

    /// Setlist position numbers, promoted to a design element: large, tabular,
    /// and dim until the row is selected.
    static let positionNumeral = TextStyle(size: 26, weight: .heavy, tracking: -1.6,
                                           monospacedDigits: true)
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
        Text("Transitions").textStyle(.nav).foregroundStyle(.appInkDim)
        Text("Kolter · 124.0 BPM").textStyle(.meta).foregroundStyle(.appInkDim)
        Text("128.5").textStyle(.numeric).foregroundStyle(.appInkDim)
        Text("Slow burn into the 5am stretch.").textStyle(.body).foregroundStyle(.appInkDim)
        Text("06").textStyle(.positionNumeral).foregroundStyle(.appAccent)
    }
    .foregroundStyle(.appInk)
    .padding(40)
    .frame(width: 720, alignment: .leading)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
