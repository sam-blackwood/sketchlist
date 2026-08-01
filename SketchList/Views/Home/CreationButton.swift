//
//  CreationButton.swift
//  SketchList
//
//  The creation call-to-action on Home: "What would you like to build?" is
//  answered by three of these — Setlist, Playlist, Transition.
//
//  Implements the settled specification in UI_DESIGN.md § Screen: Home.
//  Reference prototype: Design/prototypes/home-buttons.html, treatment A.
//
//    At rest   black block, 2pt white rule, white ink and icon
//    On hover  the block fills acid, ink and icon invert to black
//
//  The three are deliberately monochrome and are told apart by icon and label
//  rather than by colour. Colour on Home lives in the headline and the recents
//  swatches, which leaves acid free to mean one thing app-wide: selected.
//

import SwiftUI

struct CreationButton: View {
    /// Small monospace line above the title, e.g. "New".
    let label: String

    /// The thing being created, e.g. "Setlist".
    let title: String

    /// Which entity mark to draw. See `EntityIcon`.
    let icon: EntityIcon.Kind

    let action: () -> Void

    @State private var isHovering = false

    // MARK: Body

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Metrics.Space.regular) {
                EntityIcon(kind: icon, size: Self.iconSize)

                VStack(alignment: .leading, spacing: Metrics.Space.tight) {
                    Text(label)
                        .textStyle(.label)
                        .opacity(Self.labelOpacity)
                    Text(title)
                        .textStyle(.title)
                }
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Metrics.Space.loose)
            .padding(.horizontal, Metrics.Space.roomy)
            .background(fill)
            .overlay(rule)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // On the Button itself, not on the label inside it. Inside, the Button
        // still sizes to its own content, so an HStack hands each one its ideal
        // width and splits only the leftover — making "TRANSITION" wider than
        // "SETLIST". Out here every button claims an equal flexible share.
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
        // .plain strips AppKit's cursor handling along with its chrome, so the
        // pointing hand has to be asked for explicitly.
        .pointerStyle(.link)
        .accessibilityLabel(Text(verbatim: "\(label) \(title)"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Pieces

    private var ink: Color {
        isHovering ? .appOnAccent : .appInk
    }

    private var fill: some View {
        Rectangle().fill(isHovering ? Color.appAccent : Color.appBackground)
    }

    /// `strokeBorder` rather than `stroke`: a plain stroke straddles the path and
    /// spills half its width outside the frame, which would eat into the 6pt gap
    /// between buttons and make the row look unevenly spaced.
    private var rule: some View {
        Rectangle()
            .strokeBorder(isHovering ? Color.appAccent : Color.appInk,
                          lineWidth: Metrics.Stroke.rule)
    }

    // MARK: Constants

    private static let iconSize: CGFloat = 26
    private static let labelOpacity: CGFloat = 0.85
}

// MARK: - Preview

#Preview("Creation row") {
    VStack(alignment: .leading, spacing: Metrics.Space.section) {
        Text("Hover any button").textStyle(.label).foregroundStyle(.appInkFaint)

        // Metrics.Space.seam — the three read as one object made of parts.
        HStack(spacing: Metrics.Space.seam) {
            CreationButton(label: "New", title: "Setlist", icon: .setlist) {}
            CreationButton(label: "New", title: "Playlist", icon: .playlist) {}
            CreationButton(label: "New", title: "Transition", icon: .transition) {}
        }
    }
    .padding(Metrics.Space.screen)
    .frame(width: 860)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
