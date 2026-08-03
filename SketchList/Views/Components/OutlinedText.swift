//
//  OutlinedText.swift
//  SketchList
//
//  Hollow type — a word drawn as its glyph outlines rather than filled.
//
//  Used for "YOU" in the Home headline, where it is the only stroked element on
//  the screen (UI_DESIGN.md § Screen: Home). SwiftUI has no equivalent of CSS's
//  `-webkit-text-stroke`, and there is no way to fake it with blend modes: any
//  attempt to punch a smaller copy out of a larger one fails because glyphs do
//  not scale uniformly about their own contours. So the outlines are taken from
//  the font directly via Core Text and stroked as a `Shape`.
//
//  It takes a `TextStyle` rather than loose numbers, so an outlined word and the
//  filled words beside it are guaranteed to share a size, weight and tracking.
//

import AppKit
import CoreText
import SwiftUI

struct OutlinedText: View {
    let text: String
    let style: TextStyle
    var lineWidth: CGFloat = 2

    var body: some View {
        let shape = GlyphOutline(text: style.applyingCase(to: text),
                                 style: style,
                                 lineWidth: lineWidth)
        let size = shape.visualSize

        shape
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
            .frame(width: size.width, height: size.height)
            // Publish a real baseline. Without this, aligning against `Text` in
            // an HStack falls back to this view's bottom edge, which is neither
            // the baseline nor a fixed distance from it.
            .alignmentGuide(.firstTextBaseline) { _ in shape.baselineOffset }
            .alignmentGuide(.lastTextBaseline) { _ in shape.baselineOffset }
            .accessibilityLabel(Text(verbatim: text))
    }
}

// MARK: - Glyph outlines

/// The combined outline of a string's glyphs, in SwiftUI's y-down space.
private struct GlyphOutline: Shape {
    let text: String
    let style: TextStyle
    let lineWidth: CGFloat

    /// Bounds of the raw glyph outlines in Core Text space: origin on the
    /// baseline, y increasing upward. `maxY` is how far the tallest glyph rises
    /// above the baseline; `minY` is negative when anything drops below it.
    private var glyphBounds: CGRect {
        combinedPath()?.boundingBoxOfPath ?? .zero
    }

    /// Distance from the top of this view's frame down to the text baseline.
    ///
    /// Derived rather than assumed. Round letters *overshoot* — the "O" in YOU
    /// dips a fraction below the baseline — so the bottom of the bounding box
    /// is not the baseline, and treating it as one leaves the word sitting low
    /// against the text beside it.
    var baselineOffset: CGFloat {
        max(glyphBounds.maxY, 0) + lineWidth / 2
    }

    /// Frame size: the glyphs' full vertical extent including any overshoot,
    /// plus the stroke, which straddles the contour and so needs half its width
    /// of clearance on every side.
    var visualSize: CGSize {
        let bounds = glyphBounds
        let above = max(bounds.maxY, 0)
        let below = min(bounds.minY, 0)
        return CGSize(width: bounds.width + lineWidth,
                      height: (above - below) + lineWidth)
    }

    func path(in _: CGRect) -> Path {
        guard let combined = combinedPath() else { return Path() }
        let bounds = combined.boundingBoxOfPath
        guard bounds.width > 0, bounds.height > 0 else { return Path() }

        // Left-align and inset by half the stroke, flip Core Text's y-up axis to
        // SwiftUI's y-down, then drop the whole thing so the baseline lands at
        // `baselineOffset`. Anything below the baseline falls past it naturally.
        var transform = CGAffineTransform(translationX: -bounds.minX + lineWidth / 2, y: 0)
            .concatenating(CGAffineTransform(scaleX: 1, y: -1))
            .concatenating(CGAffineTransform(translationX: 0, y: baselineOffset))

        guard let flipped = combined.copy(using: &transform) else { return Path() }
        return Path(flipped)
    }

    // MARK: Core Text

    private func combinedPath() -> CGPath? {
        let attributed = NSAttributedString(
            string: text,
            attributes: [.font: style.appKitFont, .kern: style.tracking]
        )

        let line = CTLineCreateWithAttributedString(attributed)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return nil }

        let combined = CGMutablePath()
        for run in runs {
            let runFont = runFont(for: run) ?? style.appKitFont
            let count = CTRunGetGlyphCount(run)
            guard count > 0 else { continue }

            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRangeMake(0, count), &glyphs)
            CTRunGetPositions(run, CFRangeMake(0, count), &positions)

            for index in 0 ..< count {
                guard let glyph = CTFontCreatePathForGlyph(runFont, glyphs[index], nil) else { continue }
                combined.addPath(glyph, transform: CGAffineTransform(translationX: positions[index].x,
                                                                     y: positions[index].y))
            }
        }
        return combined.isEmpty ? nil : combined
    }

    /// The font a run was actually typeset with, which may differ from the one
    /// requested if the system substituted for missing glyphs.
    private func runFont(for run: CTRun) -> CTFont? {
        let key = Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()
        guard let raw = CFDictionaryGetValue(CTRunGetAttributes(run), key) else { return nil }
        return unsafeBitCast(raw, to: CTFont.self)
    }
}

// MARK: - Preview

#Preview("Outlined type") {
    VStack(alignment: .leading, spacing: Metrics.Space.loose) {
        Text("Stroke weights — 1 and 2 read best")
            .textStyle(.label).foregroundStyle(.appInkFaint)
        HStack(alignment: .firstTextBaseline, spacing: Metrics.Space.loose) {
            ForEach([CGFloat(1), 2, 3, 4], id: \.self) { width in
                VStack(alignment: .leading, spacing: Metrics.Space.snug) {
                    OutlinedText(text: "You", style: .hero, lineWidth: width)
                    Text("\(Int(width))pt").textStyle(.meta).foregroundStyle(.appInkFaint)
                }
            }
        }

        Text("In place, against filled type")
            .textStyle(.label).foregroundStyle(.appInkFaint)
        VStack(alignment: .leading, spacing: 0) {
            Text("What would").textStyle(.hero)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                OutlinedText(text: "You", style: .hero)
                Text(" like").textStyle(.hero)
            }
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("to ").textStyle(.hero)
                Text("build").textStyle(.hero).foregroundStyle(.appHot)
                Text("?").textStyle(.hero)
            }
        }
    }
    .foregroundStyle(.appInk)
    .padding(Metrics.Space.screen)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
