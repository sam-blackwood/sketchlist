//
//  PreviewSupport.swift
//  SketchList
//
//  An in-memory store with sample data, for Previews of views that read from
//  SwiftData.
//
//  Most components take plain values and need none of this — that is deliberate,
//  and why `EntityRow` and friends preview without a container. This exists for
//  the handful of views that own `@Query` properties and therefore cannot.
//
//  DEBUG-only: none of it ships.
//

#if DEBUG

    import SwiftData
    import SwiftUI

    /// Builds a throwaway store and hands it to `content`.
    ///
    /// ```swift
    /// #Preview { PreviewStore { HomeView().modelContainer($0) } }
    /// ```
    struct PreviewStore<Content: View>: View {
        private let container: ModelContainer?
        private let content: (ModelContainer) -> Content

        @MainActor
        init(seeded: Bool = true, @ViewBuilder content: @escaping (ModelContainer) -> Content) {
            self.content = content
            container = Self.makeContainer(seeded: seeded)
        }

        var body: some View {
            if let container {
                content(container)
            } else {
                Text("Preview store unavailable")
                    .textStyle(.meta)
                    .foregroundStyle(.appInkFaint)
                    .padding(Metrics.Space.screen)
                    .background(Color.appBackground)
            }
        }

        @MainActor
        private static func makeContainer(seeded: Bool) -> ModelContainer? {
            guard let container = try? ModelContainer.inMemory() else { return nil }
            if seeded { seed(ModelContext(container)) }
            return container
        }

        // MARK: Sample data

        @MainActor
        private static func seed(_ context: ModelContext) {
            let now = Date.now
            func ago(_ interval: TimeInterval) -> Date { now.addingTimeInterval(-interval) }

            // Tracks exist mainly so counts and the library summary aren't zero.
            // Created directly rather than through TrackService, so its
            // "at least one artist" rule doesn't apply — fine for a preview.
            let tracks: [Track] = [
                Track(title: "Nightdrive", bpm: 124, key: .k8A, duration: 401),
                Track(title: "Low Ceiling", bpm: 128, key: .k9A, duration: 422),
                Track(title: "Tsuki", bpm: 131, key: .k9B, duration: 358),
                Track(title: "Ferrofluid", bpm: 130, key: .k4B, duration: 372),
                Track(title: "Glass House", bpm: 133, key: .k5B, duration: 453),
                Track(title: "Ostinato", bpm: 138.5, key: .k5A, duration: 466),
                Track(title: "Vermillion", bpm: 137, key: .k11A, duration: 401),
                Track(title: "Bruk", bpm: 134, key: .k12B, duration: 388),
            ]
            tracks.forEach(context.insert)

            let setlists = [
                ("Warehouse Closing", ago(2 * 3600), 6),
                ("Sunday Rooftop", ago(16 * 86400), 5),
                ("Basement B2B", ago(28 * 86400), 8),
                ("Concrete Garden", ago(41 * 86400), 3),
            ]
            for (name, edited, count) in setlists {
                let setlist = Setlist(name: name, createdAt: edited, updatedAt: edited)
                context.insert(setlist)
                for position in 0 ..< count {
                    context.insert(SetlistTrack(setlist: setlist,
                                                track: tracks[position % tracks.count],
                                                position: position))
                }
            }

            let playlists = [
                ("Rolling & Percussive", ago(26 * 3600), 7),
                ("Late Night Vocals", ago(19 * 86400), 4),
            ]
            for (name, edited, count) in playlists {
                let playlist = Playlist(name: name, createdAt: edited, updatedAt: edited)
                context.insert(playlist)
                for position in 0 ..< count {
                    context.insert(PlaylistTrack(playlist: playlist,
                                                 track: tracks[position % tracks.count],
                                                 position: position))
                }
            }

            let transitions = [
                ("Nightdrive → Pulse Width", ago(3 * 86400)),
                ("Bruk → Vermillion", ago(34 * 86400)),
            ]
            for (name, edited) in transitions {
                let transition = Transition(name: name, createdAt: edited, updatedAt: edited)
                context.insert(transition)
                for position in 0 ..< 2 {
                    context.insert(TransitionTrack(transition: transition,
                                                   track: tracks[position],
                                                   position: position))
                }
            }

            try? context.save()
        }
    }

#endif
