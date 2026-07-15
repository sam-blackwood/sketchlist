//
//  String+Extensions.swift
//  SketchList
//
//  Small, general-purpose String helpers shared across the app.
//

import Foundation

extension String {
    /// The string trimmed of surrounding whitespace and newlines, or `nil` if the
    /// result is empty. Useful for validating user-entered names: `nil` means "blank".
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
