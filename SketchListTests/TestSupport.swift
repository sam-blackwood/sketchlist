//
//  TestSupport.swift
//  SketchListTests
//
//  Small shared helpers for tests — assertion-based and scratch alike.
//

import Foundation
@testable import SketchList

enum TestSupport {

    /// Prints a list of tracks with their key and BPM, bracketed by a labeled
    /// header/footer. Handy for eyeballing recommendation output in scratch tests.
    ///
    /// - Parameters:
    ///   - tracks: The tracks to print, in order.
    ///   - label: Heading used in the header/footer (e.g. "Recommendations").
    static func printTracks(_ tracks: [Track], label: String = "Tracks") {
        print("---------- \(label) (\(tracks.count)) ----------")
        for track in tracks {
            print("Title: \(track.title) [\(track.key.rawValue) @ \(track.bpm)]")
        }
        print("---------- End \(label) ----------")
    }
}
