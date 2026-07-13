//
//  RecommendationServiceTests.swift
//  SketchListTests
//

import Foundation
import Testing
import SwiftData
@testable import SketchList

@MainActor
@Suite struct RecommendationServiceTests {

    @MainActor
    @Suite("getRecommendationsForSingleTrack(sourceKey:sourceBPM:candidates:limit:)")
    struct GetRecommendationsForSingleTrack {

        let container: ModelContainer
        let recommendationService: RecommendationService

        init() throws {
            container = try .inMemory()
            try MockTracks.seed(into: container.mainContext)
            recommendationService = RecommendationService()
        }

        @Test("Returns exactly `limit` recommendations when enough candidates exist")
        func returnsRequestedNumberOfResults() throws {
            let library = try container.mainContext.fetch(FetchDescriptor<Track>())
            let recommendationLimit = 10
            let recommendations = recommendationService.getRecommendationsForSingleTrack(
                sourceKey: CamelotKey.k12B, sourceBPM: 75.0, candidates: library, limit: recommendationLimit)

            #expect(recommendations.count == recommendationLimit,
                    "Should generate \(recommendationLimit) recommendations")
        }

        @Test("Compatible keys wrap around the wheel (adjacent number, ±1 mod 12)", arguments: [
            (CamelotKey.k12B, CamelotKey.k1B),   // major wheel, 12 -> 1
            (CamelotKey.k1B,  CamelotKey.k12B),  // major wheel, 1 -> 12
            (CamelotKey.k12A, CamelotKey.k1A),   // minor wheel, 12 -> 1
            (CamelotKey.k1A,  CamelotKey.k12A),  // minor wheel, 1 -> 12
        ])
        func wrapsAroundWheel(source: CamelotKey, expected: CamelotKey) throws {
            let library = try container.mainContext.fetch(FetchDescriptor<Track>())
            let recommendations = recommendationService.getRecommendationsForSingleTrack(
                sourceKey: source, sourceBPM: 75.0, candidates: library, limit: 10)

            #expect(recommendations.contains(where: { $0.key == expected }),
                    "Source \(source.rawValue) should surface at least one \(expected.rawValue) candidate via wheel wrap")
        }

        @Test("Octave-equivalent tempos (half/double) count as compatible for the same key and its relative", arguments: [
            (75.0,  150.0, CamelotKey.k3B),   // doubling, same key
            (75.0,  150.0, CamelotKey.k3A),   // doubling, relative (same number, opposite letter)
            (150.0, 75.0,  CamelotKey.k3B),   // halving, same key
            (150.0, 75.0,  CamelotKey.k3A),   // halving, relative
        ])
        func octaveEquivalentTempo(sourceBPM: Double, matchBPM: Double, expectedKey: CamelotKey) throws {
            let library = try container.mainContext.fetch(FetchDescriptor<Track>())
            let recommendations = recommendationService.getRecommendationsForSingleTrack(
                sourceKey: CamelotKey.k3B, sourceBPM: sourceBPM, candidates: library, limit: 10)

            #expect(recommendations.contains(where: { $0.bpm == matchBPM && $0.key == expectedKey }),
                    "Source 3B @ \(sourceBPM) should surface a \(expectedKey.rawValue) @ \(matchBPM) candidate (octave-equivalent tempo)")
        }
        
        @Test("Every recommendation is a valid Camelot transition (same key, ±1 on the wheel, or relative major/minor)",
              arguments: CamelotKey.allCases)
        func recommendationsAreValidTransitions(source: CamelotKey) throws {
            let library = try container.mainContext.fetch(FetchDescriptor<Track>())
            let recommendations = recommendationService.getRecommendationsForSingleTrack(
                sourceKey: source, sourceBPM: 100.0, candidates: library, limit: 100)

            let validKeys = RecommendationOracle.compatibleKeys(for: source)
            let invalid = recommendations.filter { !validKeys.contains($0.key) }

            #expect(invalid.isEmpty,
                    "Source \(source.rawValue): every recommendation must be the same key, ±1 on the wheel, or the relative key — found invalid \(invalid.map { $0.key.rawValue })")
        }

        @Test("Recommendations are ordered by descending BPM score (closest tempo first)")
        func recommendationsSortedByBpmScore() throws {
            // A bespoke candidate set (not the seeded library): all key 8B, so ranking is
            // purely tempo, against source 8B @ 128. BPMs are chosen for distinct octave-
            // distances — no ties — so exactly one order is correct. Input is deliberately
            // shuffled to prove the service sorts rather than echoing the input order.
            let bpms: [Double] = [140, 100, 128, 168, 132, 152]
            let candidates = bpms.map { Track(title: "8B @ \($0)", bpm: $0, key: .k8B, duration: 0) }

            let recommendations = recommendationService.getRecommendationsForSingleTrack(
                sourceKey: .k8B, sourceBPM: 128, candidates: candidates, limit: bpms.count)

            #expect(recommendations.map(\.bpm) == [128, 132, 140, 152, 100, 168],
                    "Should rank by tempo closeness to 128 (octave-aware); got \(recommendations.map(\.bpm))")
        }
    }
}
