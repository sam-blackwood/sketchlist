//
//  HeroHeadline.swift
//  SketchList
//
//  "What would YOU like to build?" — the question Home opens with.
//
//  One word is emphasized: **YOU**, drawn hollow, the only stroked element on
//  the screen. BUILD was briefly hot pink as a second emphasis; that color now
//  belongs to the library summary line above, and the headline reads better
//  with a single point of emphasis than with two competing ones.
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

            Text("to build?")
        }
        .textStyle(style)
        .foregroundStyle(.appInk)
        .fixedSize(horizontal: false, vertical: true)
        // Trim the line box down to the visible letterforms. A Text frame runs
        // from the font's ascender to its descender, but this headline is all
        // capitals — so there is empty space above the caps and below the
        // baseline that belongs to no glyph. At 72pt that is about 14pt on top
        // and 15pt underneath, which shows up as a gap nobody asked for and
        // makes every spacing value around it a lie.
        .padding(.top, -leadingInset)
        .padding(.bottom, -trailingInset)
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

    /// Empty space above the capitals: everything between the font's ascender —
    /// where the frame starts — and the top of a capital letter. Taken from the
    /// font rather than estimated, since it varies by face and weight.
    private var leadingInset: CGFloat {
        let font = style.appKitFont
        return max(0, font.ascender - font.capHeight)
    }

    /// Empty space below the baseline. Nothing in an all-capitals headline
    /// descends into it.
    private var trailingInset: CGFloat {
        max(0, -style.appKitFont.descender)
    }

    private static let lineHeightRatio: CGFloat = 0.88
    private static let systemLeadingRatio: CGFloat = 1.2
}

// MARK: - Preview

#Preview("Hero") {
    VStack(alignment: .leading, spacing: Metrics.Space.section) {
        VStack(alignment: .leading, spacing: Metrics.Space.loose) {
            Text("412 tracks · 9 setlists · 14 playlists · 37 transitions")
                .textStyle(.label)
                .foregroundStyle(.appHot)
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
