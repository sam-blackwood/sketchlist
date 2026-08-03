//
//  DefaultArtwork.swift
//  SketchList
//
//  The cover art an entity has before anyone gives it one.
//
//  Every setlist, playlist and transition always has artwork — there is no
//  "no artwork" state, only a default. That default is the entity's own mark on
//  a colored square, colored per entity so a list of twenty setlists is twenty
//  different squares rather than twenty identical ones. Artwork's job in a list
//  is recognition; a constant mark would be decoration occupying a functional
//  slot.
//
//  The color is seeded from the entity's **identifier**, not its name. Seeding
//  from the name would mean renaming a setlist silently repainted its artwork,
//  which is a jarring thing to have happen to an object you were only relabeling.
//  An identifier never changes, so the artwork is stable for the life of the
//  entity. (Nothing is lost by this: an earlier design put the entity's first
//  initial in the square, which did want to agree with the name — the icon
//  replaced it.)
//
//  Reference prototype: Design/prototypes/entity-artwork.html — "muted" at
//  "full circle".
//

import SwiftUI

enum DefaultArtwork {
    /// The two colors making up one default cover: the square and the mark on it.
    struct Palette {
        let square: Color
        let ink: Color
    }

    /// Colors for an entity, seeded by something stable about it — in practice
    /// `entity.id.uuidString`.
    static func palette(seed: String) -> Palette {
        let hue = hue(seed: seed)
        let inkComponents = hsl(hue: hue, saturation: Ink.saturation, lightness: Ink.lightness)

        // Walk the square darker until the mark clears the contrast target.
        // A single lightness across the wheel does not work: blues and violets
        // are far darker than yellows at the same nominal value, so a fixed
        // number leaves some marks legible and others muddy.
        var lightness = Square.maxLightness
        while lightness > Square.minLightness {
            let squareComponents = hsl(hue: hue, saturation: Square.saturation, lightness: lightness)
            if contrastRatio(squareComponents, inkComponents) >= minimumContrast { break }
            lightness -= Square.step
        }

        return Palette(square: color(hsl(hue: hue, saturation: Square.saturation, lightness: lightness)),
                       ink: color(inkComponents))
    }

    // MARK: Hue

    /// Hues are quantized into twelve buckets 30° apart rather than taken raw
    /// from the hash.
    ///
    /// An unquantized hash lands pairs a few degrees apart, which reads as
    /// "almost the same color" — worse than either matching outright or
    /// clearly differing. With buckets, two entities are unmistakably the same
    /// color or unmistakably not.
    ///
    /// The whole circle is used, including the yellow-and-gold band that acid
    /// owns elsewhere. Acid's reservation exists so a *creation button* is never
    /// mistaken for a selection; a 36pt square in a fixed position that never
    /// changes state is not at risk of that, and excluding those hues removes
    /// every bright color from the set.
    static func hue(seed: String) -> Double {
        let bucket = Int(stableHash(seed) % UInt32(bucketCount))
        return Double(bucket) * bucketWidth
    }

    /// Every hue the app can produce. Twelve values, 30° apart.
    static var allHues: [Double] {
        (0 ..< bucketCount).map { Double($0) * bucketWidth }
    }

    /// A hash that is stable across launches.
    ///
    /// Deliberately not `hashValue`: Swift seeds its hasher randomly per
    /// process, so using it here would give every entity a different color
    /// every time the app opened. This is the same rolling hash the prototype
    /// uses, over UTF-16 units, so Swift and the HTML agree exactly.
    static func stableHash(_ string: String) -> UInt32 {
        var hash: UInt32 = 0
        for unit in string.utf16 {
            hash = hash &* 31 &+ UInt32(unit)
        }
        return hash
    }

    // MARK: Constants

    private static let bucketCount = 12
    private static var bucketWidth: Double { 360.0 / Double(bucketCount) }
    private static let minimumContrast = 3.2

    private enum Square {
        static let saturation = 0.34
        static let maxLightness = 0.42
        static let minLightness = 0.12
        static let step = 0.02
    }

    private enum Ink {
        static let saturation = 0.72
        static let lightness = 0.68
    }
}

// MARK: - Color math

private typealias RGB = (red: Double, green: Double, blue: Double)

/// HSL to RGB. SwiftUI offers HSB, which is a different model — matching the
/// prototype means doing HSL properly rather than approximating.
private func hsl(hue: Double, saturation: Double, lightness: Double) -> RGB {
    let a = saturation * min(lightness, 1 - lightness)
    func channel(_ n: Double) -> Double {
        let k = (n + hue / 30).truncatingRemainder(dividingBy: 12)
        return lightness - a * max(-1, min(k - 3, 9 - k, 1))
    }
    return (channel(0), channel(8), channel(4))
}

private func color(_ rgb: RGB) -> Color {
    Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
}

private func relativeLuminance(_ rgb: RGB) -> Double {
    func linear(_ value: Double) -> Double {
        value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(rgb.red) + 0.7152 * linear(rgb.green) + 0.0722 * linear(rgb.blue)
}

private func contrastRatio(_ first: RGB, _ second: RGB) -> Double {
    let a = relativeLuminance(first)
    let b = relativeLuminance(second)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
}

// MARK: - Preview

#Preview("Default artwork — every bucket") {
    VStack(alignment: .leading, spacing: Metrics.Space.loose) {
        Text("Ten entities").textStyle(.label).foregroundStyle(.appInkFaint)
        HStack(spacing: Metrics.Space.snug) {
            ForEach(1 ... 10, id: \.self) { index in
                let palette = DefaultArtwork.palette(seed: previewIdentifier(index).uuidString)
                Rectangle()
                    .fill(palette.square)
                    .frame(width: Metrics.Row.artwork, height: Metrics.Row.artwork)
                    .overlay {
                        EntityIcon(kind: .setlist, size: Metrics.Row.artworkGlyph)
                            .foregroundStyle(palette.ink)
                    }
            }
        }

        Text("All twelve buckets").textStyle(.label).foregroundStyle(.appInkFaint)
        HStack(spacing: Metrics.Space.snug) {
            ForEach(DefaultArtwork.allHues, id: \.self) { hue in
                // Seeds chosen only to land one item in each bucket.
                let palette = DefaultArtwork.palette(seed: bucketProbe(hue: hue))
                Rectangle()
                    .fill(palette.square)
                    .frame(width: Metrics.Row.artwork, height: Metrics.Row.artwork)
                    .overlay {
                        EntityIcon(kind: .transition, size: Metrics.Row.artworkGlyph)
                            .foregroundStyle(palette.ink)
                    }
            }
        }
    }
    .padding(Metrics.Space.screen)
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

/// Finds a short seed that hashes to `hue`, so the Preview can show the whole
/// palette rather than whichever buckets the sample entities happen to hit.
private func bucketProbe(hue: Double) -> String {
    for letter in "abcdefghijklmnopqrstuvwxyz"
        where DefaultArtwork.hue(seed: String(letter)) == hue
    {
        return String(letter)
    }
    return "a"
}

/// A stable, readable identifier for Previews — real entities supply their own.
private func previewIdentifier(_ number: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number)) ?? UUID()
}
