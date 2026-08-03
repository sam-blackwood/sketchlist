//
//  HeroHeadline.swift
//  SketchList
//
//  "What would YOU like to BUILD?" — the question Home opens with.
//
//  Two words are emphasised by two different mechanisms so neither repeats the
//  other (UI_DESIGN.md § Screen: Home):
//
//    YOU    hollow — the only stroked element on the screen
//    BUILD  solid hot pink — the app's own voice
//
//  The three lines are composed by hand rather than left to wrap. An outlined
//  word cannot be concatenated into a `Text`, because the outline is a
//  View-level shape rather than a Text-level attribute, so the line containing
//  it has to be an `HStack`. Fixed breaks are the deliberate choice anyway —
//  this is poster language, and the shape of the three lines is the design.
//

import SwiftUI

struct HeroHeadline: View {
    /// Parameterised so the Preview can compare sizes without editing the token.
    var style: TextStyle = .hero

    var body: some View {
        VStack(alignment: .leading, spacing: lineGap) {
            Text("What would")

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // A shape-backed view reports its bottom edge as its first text
                // baseline. That happens to be correct here: "YOU" has no
                // descender, so the bottom of its outline *is* its baseline,
                // and it lands level with the filled text beside it.
                OutlinedText(text: "You", style: style)
                Text(" like")
            }

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("to ")
                Text("build").foregroundStyle(.appHot)
                Text("?")
            }
        }
        .textStyle(style)
        .foregroundStyle(.appInk)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "What would you like to build?"))
        .accessibilityAddTraits(.isHeader)
    }

    /// Negative spacing to pull the lines to the poster's tight leading.
    ///
    /// The prototype sets `line-height: 0.88`. Stacked `Text` views each carry
    /// their own line height — roughly 1.2× the point size for the system face —
    /// so closing to 0.88 means removing the difference. The 1.2 is an
    /// approximation of SF's default leading; nudge it if the lines look loose
    /// or collide.
    private var lineGap: CGFloat {
        style.size * (Self.lineHeightRatio - Self.systemLeadingRatio)
    }

    private static let lineHeightRatio: CGFloat = 0.88
    private static let systemLeadingRatio: CGFloat = 1.2
}

// MARK: - Preview

#Preview("Hero") {
    VStack(alignment: .leading, spacing: Metrics.Space.section) {
        VStack(alignment: .leading, spacing: Metrics.Space.loose) {
            Text("412 tracks · 9 setlists · 37 transitions · avg 129.4 bpm")
                .textStyle(.label)
                .foregroundStyle(.appInkFaint)
            HeroHeadline()
        }

        HStack(spacing: Metrics.Space.seam) {
            CreationButton(label: "New", title: "Setlist", icon: .setlist) {}
            CreationButton(label: "New", title: "Playlist", icon: .playlist) {}
            CreationButton(label: "New", title: "Transition", icon: .transition) {}
        }
    }
    .padding(Metrics.Space.screen)
    .frame(width: 980, alignment: .leading)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
