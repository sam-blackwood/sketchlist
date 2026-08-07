//
//  PlaceholderScreen.swift
//  SketchList
//
//  A stand-in for a destination whose screen has not been built.
//
//  Deliberately plain. A placeholder that tries to look finished is worse than
//  one that admits what it is — it hides which parts of the app are real, and it
//  invites design decisions about a screen nobody has thought through yet.
//
//  Two of these (Mix Generator, Setlist Order) stand in for features listed as
//  post-v1 in SYSTEM_DESIGN.md, so they will outlive the rest.
//

import SwiftUI

struct PlaceholderScreen: View {
    let destination: SidebarDestination

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.Space.regular) {
            Text(destination.title)
                .textStyle(.display)
                .foregroundStyle(.appInk)

            Text("Not built yet")
                .textStyle(.nav)
                .foregroundStyle(.appInkFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.appBackground)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Placeholder") {
    PlaceholderScreen(destination: .setlists)
        .frame(width: 700, height: 460)
        .preferredColorScheme(.dark)
}
