//
//  RecommendationService.swift
//  SketchList
//

import Foundation

final class RecommendationService {
    
    /// Scores how closely two tempos match, on a 0...1 scale where higher is better.
    ///
    /// The comparison is **octave-equivalent**: half-time and double-time tracks count
    /// as a perfect tempo match. A 70 BPM and a 140 BPM track share the same beat grid
    /// (every other beat of the faster track lands on a beat of the slower one), so they
    /// beatmatch cleanly with no change to either track. To capture that, tempos are
    /// compared in log space — taking `log2` of their ratio maps every octave-equivalent
    /// tempo (same, 2×, 0.5×, 4×, …) onto an integer, so "tempo closeness" becomes
    /// distance to the nearest integer.
    ///
    /// The result is `1.0` when the tempos are octave-aligned (identical, double, or half),
    /// and falls to `0.0` at the worst case — a ratio of √2 (≈1.414), the point exactly
    /// between "same" and "double" where a track is maximally ambiguous to beatmatch.
    ///
    /// Only the octave relationship (2× / 0.5×) is considered in v1; triplet and other
    /// ratios are out of scope (see SYSTEM_DESIGN.md § Compatibility primitive).
    ///
    /// - Parameters:
    ///   - bpm1: The source (reference) tempo, in BPM. Must be positive.
    ///   - bpm2: The candidate tempo being scored against the source, in BPM. Must be positive.
    /// - Returns: A tempo-similarity score in `0...1`; `0` if either tempo is non-positive.
    private func computeBpmScore(bpm1: Double, bpm2: Double) -> Double {
        guard bpm1 > 0, bpm2 > 0 else { return 0.0 }
        let r = bpm2 / bpm1
        let d = log2(r)
        let octaveDistance = abs(d - d.rounded())
        let bpmScore = 1 - 2 * octaveDistance
        return bpmScore
    }
    
    func getRecommendationsForSingleTrack(
        sourceKey: CamelotKey,
        sourceBPM: Double,
        candidates: [Track],
        limit: Int
    ) -> [Track] {
        // Zip tracks and their tempoScore together
        var bestCandidates: [(track: Track, bpmScore: Double)] = []

        for candidate in candidates {
            let isCompatible = CamelotKey.isCompatible(key1: sourceKey, key2: candidate.key)

            // TODO: don't let bestCandidates grow beyond limit size as candidates could be the entire user's library
            if isCompatible {
                let bpmScore = computeBpmScore(bpm1: sourceBPM, bpm2: candidate.bpm)
                bestCandidates.append((track: candidate, bpmScore: bpmScore))
            }
        }

        return bestCandidates
            .sorted { $0.bpmScore > $1.bpmScore }
            .prefix(limit)
            .map { $0.track }
    }
    
    func recommendSetlist(startSong: Track, candidates: [Track], limit: Int) -> [Track] {
        var setlist = [startSong]
        var currentSong = startSong
        var remaining = candidates.filter({ $0.id != startSong.id })

        for _ in 0..<limit {
            // Algorithm hard-codes sampling from 5 best candidates for next track selection
            let bestMatches = getRecommendationsForSingleTrack(sourceKey: currentSong.key, sourceBPM: currentSong.bpm, candidates: remaining, limit: 10)

            guard let nextSong = bestMatches.randomElement() else { return setlist }
            // Append nextSong to setlist and remove it from the remaining tracks
            setlist.append(nextSong)
            remaining.removeAll(where: { $0.id == nextSong.id })
            // Update currentSong once done processing nextSong
            currentSong = nextSong
        }

        return setlist
    }
}
