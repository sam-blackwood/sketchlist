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
                .background(Color("AppBackground"))
        }
        .modelContainer(modelContainer)
    }
}
