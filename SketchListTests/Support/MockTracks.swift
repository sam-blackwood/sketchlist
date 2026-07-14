//
//  MockTracks.swift
//  SketchListTests
//
//  Deterministic synthetic library for unit-testing the recommendation algorithm.
//  Generic tracks spanning all 24 Camelot keys with evenly-spaced BPMs, so tests can
//  assert exact compatibility and ranking without depending on real-world data.
//
//  This is the *committed* fixture. The realistic (songs.csv) library lives under
//  SketchListTests/Scratch/ and is gitignored — it's for local eyeballing only.
//

import Foundation
@testable import SketchList
import SwiftData

enum MockTracks {
    /// Builds a deterministic library: `perKey` tracks for every Camelot key, with
    /// BPMs stepping by `spacing` from `bpmRange.lowerBound` (capped at the upper bound).
    ///
    /// Defaults — `perKey: 25`, `60...180`, step `5` — give exactly 25 tracks per key
    /// across 60, 65, …, 180 (24 × 25 = 600 total). That range at that step also contains
    /// exact octave pairs (60/120, 70/140, 75/150, 90/180), so half/double-time BPM
    /// scoring gets exercised without any special-casing.
    ///
    /// Everything is deterministic (no randomness) so ranking assertions are stable.
    /// Titles/artists encode the Camelot code + index (e.g. "1A Track 3" / "1A Artist 3")
    /// so printed output is self-describing. `duration` is an unused placeholder (0).
    ///
    /// - Parameters:
    ///   - perKey: Number of tracks generated per Camelot key.
    ///   - bpmRange: Inclusive BPM span; generation starts at the lower bound.
    ///   - spacing: BPM step between consecutive tracks within a key.
    static func all(
        perKey: Int = 25,
        bpmRange: ClosedRange<Double> = 60 ... 180,
        spacing: Double = 5
    )
        -> [Track]
    {
        CamelotKey.allCases.flatMap { key in
            (0 ..< perKey).map { index in
                let bpm = min(bpmRange.lowerBound + Double(index) * spacing, bpmRange.upperBound)
                return Track(
                    title: "\(key.rawValue) Track \(index + 1)",
                    bpm: bpm,
                    key: key,
                    duration: 0
                )
            }
        }
    }

    /// Inserts the generated library into `context` and saves. Returns the tracks.
    @discardableResult
    static func seed(
        into context: ModelContext,
        perKey: Int = 25,
        bpmRange: ClosedRange<Double> = 60 ... 180,
        spacing: Double = 5
    )
        throws -> [Track]
    {
        let tracks = all(perKey: perKey, bpmRange: bpmRange, spacing: spacing)
        for track in tracks {
            context.insert(track)
        }
        try context.save()
        return tracks
    }
}
