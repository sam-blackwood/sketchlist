//
//  SketchListApp.swift
//  SketchList
//
//  Created by Sam Blackwood on 7/1/26.
//

import SwiftData
import SwiftUI

@main
struct SketchListApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try .app()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                // Temporary. UI_DESIGN.md calls for light and dark as
                // first-class, both designed rather than one derived from the
                // other — but the light values in the Asset Catalog are
                // placeholders nobody has looked at, so following the system
                // appearance currently ships a palette that was never designed.
                // Remove this line once light mode exists.
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
