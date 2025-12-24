import SwiftUI
import Model
import Observation

@Observable
final class FinishedEpisodes {
    
    static let shared = FinishedEpisodes()
    
    private let store = UserDefaults.standard
    private let defaultsKey = "finished_episodes"
    private var finishedEpisodeIDs: Set<String>

    init() {
        self.finishedEpisodeIDs = Set(store.stringArray(forKey: defaultsKey) ?? [])
    }

    func isFinished(_ episode: EpisodeView) -> Bool {
        finishedEpisodeIDs.contains(episode.id)
    }
    
    func countFinished(in episodes: [EpisodeView]) -> Int {
        finishedEpisodeIDs.intersection(episodes.map({ $0.id })).count
    }

    func toggle(_ episode: EpisodeView) {
        if isFinished(episode) {
            finishedEpisodeIDs.remove(episode.id)
        } else {
            finishedEpisodeIDs.insert(episode.id)
        }
        save()
    }

    private func save() {
        store.set(Array(finishedEpisodeIDs), forKey: defaultsKey)
        store.synchronize()
    }
}
