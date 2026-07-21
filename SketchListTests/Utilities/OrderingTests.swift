//
//  OrderingTests.swift
//  SketchListTests
//
//  Pure tests for the Ordering utility — no SwiftData, just a throwaway Positioned type.
//  Only valid inputs are tested: out-of-bounds indices trip `assertionFailure` (a debug
//  guardrail), so exercising them would trap rather than assert.
//

import Foundation
import Testing
@testable import SketchList

/// Minimal `Positioned` conformer for exercising `Ordering`.
private final class Item: Positioned {
    let label: String
    var position: Int
    init(_ label: String, position: Int = 0) {
        self.label = label
        self.position = position
    }
}

private func makeItems(_ labels: String...) -> [Item] {
    labels.map { Item($0) }
}

struct OrderingTests {}

// MARK: - reindex

extension OrderingTests {
    @Test("reindex assigns position = index in array order, overwriting any prior values")
    func reindexAssignsContiguousPositions() {
        let list = makeItems("A", "B", "C")
        list[0].position = 9
        list[1].position = 4
        list[2].position = 7

        Ordering.reindex(list)

        #expect(list.map(\.position) == [0, 1, 2], "Positions should become 0..<count matching array order")
    }
}

// MARK: - move

extension OrderingTests {
    @Test("move follows the SwiftUI onMove convention and keeps positions contiguous", arguments: [
        (1, 3, ["A", "C", "B", "D"]), // downward: insert-before original index 3
        (3, 1, ["A", "D", "B", "C"]), // upward
        (0, 4, ["B", "C", "D", "A"]), // to end (destination == count)
        (1, 2, ["A", "B", "C", "D"]), // no-op (before the same neighbor)
        (2, 2, ["A", "B", "C", "D"]), // no-op
    ])
    func moveReordersAndReindexes(source: Int, destination: Int, expected: [String]) {
        var list = makeItems("A", "B", "C", "D")

        Ordering.move(&list, from: source, to: destination)

        #expect(list.map(\.label) == expected, "Wrong order after move(from: \(source), to: \(destination))")
        #expect(list.map(\.position) == Array(0 ..< list.count), "Positions should stay contiguous 0..<count")
    }
}

// MARK: - remove

extension OrderingTests {
    @Test("remove deletes the element at the index and reindexes the remainder")
    func removeDeletesAndReindexes() {
        var list = makeItems("A", "B", "C", "D")

        Ordering.remove(at: 1, from: &list)

        #expect(list.map(\.label) == ["A", "C", "D"], "The element at index 1 (B) should be removed")
        #expect(list.map(\.position) == [0, 1, 2], "Remaining positions should be contiguous")
    }
}

// MARK: - insert

extension OrderingTests {
    @Test("insert splices new elements at the index and reindexes everything")
    func insertSplicesAndReindexes() {
        var list = makeItems("A", "B", "C")

        Ordering.insert(makeItems("X", "Y"), at: 1, into: &list)

        #expect(list.map(\.label) == ["A", "X", "Y", "B", "C"], "New elements should be inserted at index 1")
        #expect(list.map(\.position) == [0, 1, 2, 3, 4], "All positions should be contiguous 0..<count")
    }

    @Test("insert at count appends")
    func insertAtCountAppends() {
        var list = makeItems("A", "B")

        Ordering.insert(makeItems("Z"), at: 2, into: &list)

        #expect(list.map(\.label) == ["A", "B", "Z"], "Inserting at count should append")
        #expect(list.map(\.position) == [0, 1, 2], "Positions should be contiguous after appending")
    }
}
