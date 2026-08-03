//
//  Formatting.swift
//  SketchList
//
//  Display formatting for the two values that appear on nearly every screen.
//  Kept here so a track's BPM is written the same way in a setlist, the library,
//  and a recommendation list without each view deciding for itself.
//

import Foundation

// MARK: - Duration

extension Int {
    /// Seconds rendered as a timecode: `401` → `"6:41"`, `3672` → `"1:01:12"`.
    var timecode: String {
        let seconds = abs(self)
        let s = seconds % 60
        let m = (seconds / 60) % 60
        let h = seconds / 3600

        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Tempo

extension Double {
    /// BPM to a single decimal place: `128` → `"128.0"`, `132.5` → `"132.5"`.
    ///
    /// Always shows the decimal. Tempos in a DJ library are frequently fractional,
    /// and a ragged column of "128" beside "132.5" reads as an inconsistency
    /// rather than as a whole number.
    var bpmText: String {
        String(format: "%.1f", self)
    }
}

// MARK: - Recency

extension Date {
    /// How long ago something was edited, in the shorthand a list column wants:
    /// `"14m ago"`, `"2h ago"`, `"Yesterday"`, `"Sat"`, `"12 Jul"`.
    ///
    /// Deliberately not `RelativeDateTimeFormatter`, which produces "2 hours
    /// ago" — too wide for a right-aligned metadata column, and too chatty
    /// beside the app's clipped monospace voice. Precision also drops off with
    /// age on purpose: minutes matter this morning, the day of the week matters
    /// this week, and beyond that a date is all anyone wants.
    func editedDescription(relativeTo now: Date = .now,
                           calendar: Calendar = .current) -> String
    {
        if calendar.isDateInToday(self) {
            let minutes = max(0, Int(now.timeIntervalSince(self) / 60))
            if minutes < 1 { return "Just now" }
            if minutes < 60 { return "\(minutes)m ago" }
            return "\(minutes / 60)h ago"
        }

        if calendar.isDateInYesterday(self) { return "Yesterday" }

        let days = calendar.dateComponents([.day], from: self, to: now).day ?? 0
        if days < 7 {
            return formatted(.dateTime.weekday(.abbreviated))
        }

        return formatted(.dateTime.day(.twoDigits).month(.abbreviated))
    }
}
