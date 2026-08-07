//
//  Sidebar.swift
//  SketchList
//
//  The left panel — direction **A, quiet mono** (`Design/prototypes/sidebar.html`).
//
//  Navigation is not content. It stays in the 11pt monospace voice and lets the
//  main pane hold all the display weight, which is why the destinations are set
//  in `TextStyle.nav` rather than in the display face the rest of the app shouts
//  in. Two louder directions were tried: a full acid block per selected row
//  matching the CreationButton hover, and a display-weight list. Both put a
//  permanent bright slab in the corner of every screen.
//
//  Selection is acid — text plus a rule down the leading edge — and nothing else
//  on this screen is acid, which is the whole point of the color
//  (UI_DESIGN.md § Color roles).
//
//  No wordmark. macOS puts the app name in the title bar and repeating it here
//  spends the most valuable row in the panel on something the user already
//  knows. It is one `Text` to add back if the top feels bare.
//

import SwiftUI

struct Sidebar: View {
    @Binding var selection: SidebarDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SidebarDestination.sections) { section in
                if let title = section.title {
                    Text(title)
                        .textStyle(.label)
                        .foregroundStyle(.appInkFaint)
                        .padding(.horizontal, Metrics.Space.roomy)
                        .padding(.top, Metrics.Space.loose)
                        .padding(.bottom, Metrics.Space.snug)
                }

                ForEach(section.destinations) { destination in
                    SidebarRow(destination: destination,
                               isSelected: selection == destination) {
                        selection = destination
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, Metrics.Space.regular)
        // Fills both axes so its opaque ground covers the whole column. macOS
        // paints a translucent material behind a split view's sidebar; anything
        // less than a full-bleed background lets that show through and reads as
        // a lighter seam against the content pane.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appBackground)
    }
}

// MARK: - Row

private struct SidebarRow: View {
    let destination: SidebarDestination
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.Space.regular) {
                icon
                Text(destination.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .textStyle(.nav)
            .foregroundStyle(ink)
            .padding(.horizontal, Metrics.Space.roomy)
            .frame(height: Metrics.Row.nav)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Drawn behind rather than as a leading sibling, so the marker does
            // not shift the label when it appears.
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(Color.appAccent)
                        .frame(width: Metrics.Stroke.rule)
                        .padding(.vertical, Metrics.Space.tight)
                }
            }
            .contentShape(Rectangle()) // the whole row is the target, not the text
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// One of the two is always non-nil — entity destinations wear their own
    /// mark, everything else wears a stock symbol.
    @ViewBuilder
    private var icon: some View {
        if let kind = destination.entityKind {
            EntityIcon(kind: kind, size: TextStyle.nav.size, weight: .light)
        } else if let nav = destination.navIcon {
            NavigationIcon(destination: nav)
        }
    }

    /// Acid when selected, white on hover, dim at rest. Hover goes to white
    /// rather than to acid so that acid keeps meaning *selected* — a row that
    /// turns acid under the cursor teaches that the color means "pointed at".
    private var ink: Color {
        if isSelected { .appAccent }
        else if isHovering { .appInk }
        else { .appInkDim }
    }
}

// MARK: - Preview

#Preview("Sidebar") {
    @Previewable @State var selection: SidebarDestination = .home

    HStack(spacing: 0) {
        Sidebar(selection: $selection)
            .frame(width: Metrics.Pane.sidebarIdeal)

        Divider().overlay(Color.appRule)

        VStack {
            Text(selection.title)
                .textStyle(.display)
                .foregroundStyle(.appInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    .frame(height: 560)
    .preferredColorScheme(.dark)
}
