//
//  Ordering.swift
//  SketchList
//
//  Pure, stateless helpers for maintaining contiguous 0..<n `position` values on the
//  ordered join rows (SetlistTrack / PlaylistTrack / TransitionTrack). No SwiftData
//  dependency — trivially unit-testable against any `Positioned` type.
//

import Foundation

/// A reference-type row that carries a mutable ordering `position`.
protocol Positioned: AnyObject {
    var position: Int { get set }
}

enum Ordering {
    /// Assigns `position = index` for each element, in the array's current order.
    static func reindex<T: Positioned>(_ ordered: [T]) {
        for (index, order) in ordered.enumerated() {
            order.position = index
        }
    }

    /// Moves the element at `source` to `destination`, then reindexes.
    ///
    /// `destination` uses the SwiftUI `onMove` / `Array.move(fromOffsets:toOffset:)`
    /// convention: it's the offset *before which* to insert, measured in the original
    /// array (`0...count`) — so a drag API's offset can be passed straight through.
    /// No-op if `source` isn't in `0..<count` or `destination` isn't in `0...count`.
    static func move<T: Positioned>(_ items: inout [T], from source: Int, to destination: Int) {
        guard items.indices.contains(source), (0 ... items.count).contains(destination) else {
            assertionFailure("Ordering.move: index out of bounds (source: \(source), destination: \(destination), count: \(items.count))")
            return
        }

        let movedItem = items.remove(at: source)
        // After removing `source`, a destination past it shifts left by one.
        let insertIndex = destination > source ? destination - 1 : destination
        items.insert(movedItem, at: insertIndex)
        Ordering.reindex(items)
    }

    /// Removes the element at `index`, then reindexes the remainder.
    /// No-op if `index` is out of bounds (`0..<count`).
    static func remove<T: Positioned>(at index: Int, from items: inout [T]) {
        guard items.indices.contains(index) else {
            assertionFailure("Ordering.remove: index out of bounds (index: \(index), count: \(items.count))")
            return
        }

        items.remove(at: index)
        Ordering.reindex(items)
    }

    /// Inserts `new` into `items` at `index`, then reindexes.
    /// No-op if `index` is not a valid insertion point (`0...count`).
    static func insert<T: Positioned>(_ new: [T], at index: Int, into items: inout [T]) {
        guard (0 ... items.count).contains(index) else {
            assertionFailure("Ordering.insert: invalid insertion index (index: \(index), count: \(items.count))")
            return
        }

        items.insert(contentsOf: new, at: index)
        Ordering.reindex(items)
    }
}
