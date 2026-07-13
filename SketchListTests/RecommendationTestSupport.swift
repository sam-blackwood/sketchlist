//
//  RecommendationTestSupport.swift
//  SketchListTests
//
//  Test oracles for verifying RecommendationService output — independent reference
//  implementations of the recommendation rules, kept deliberately separate from the
//  production logic. Tests compare the service against these oracles, so an oracle
//  must never be unified with (or call into) the service's own logic — that would
//  turn the check into a mirror of the implementation and defeat the point.
//

import Foundation
@testable import SketchList

enum RecommendationOracle {

    /// The keys a candidate may have to be a valid v1 transition from `source`:
    /// same key, adjacent number on the same letter (±1 mod 12), or the relative
    /// key (same number, opposite letter). Derived directly from the Camelot code,
    /// independent of the service's compatibility logic.
    static func compatibleKeys(for source: CamelotKey) -> Set<CamelotKey> {
        let raw = source.rawValue
        let letter = String(raw.suffix(1))        // "A" or "B"
        let number = Int(raw.dropLast())!         // 1...12
        let otherLetter = letter == "A" ? "B" : "A"
        func wrap(_ n: Int) -> Int { ((n - 1 + 12) % 12) + 1 }

        let codes = [
            "\(number)\(letter)",              // same key
            "\(wrap(number + 1))\(letter)",    // +1 on the wheel
            "\(wrap(number - 1))\(letter)",    // -1 on the wheel
            "\(number)\(otherLetter)",         // relative major/minor (mode swap)
        ]
        return Set(codes.compactMap(CamelotKey.init(rawValue:)))
    }
}
