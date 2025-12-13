//
//  Store.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import UIKit
import Combine
import TinyNetworking

class Store {
    static let shared = Store()
    
    private var server = Server()
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = Session.shared
            .$credentials
            .sink { [unowned self] in
                self.cachedEpisodeDetails.removeAll()
                self.server.credentials = $0.map({
                    .init(sessionId: $0, csrf: $1)
                })
            }
    }
    
    lazy private(set) var allEpisodes = Resource<[EpisodeView]>(endpoint: server.allEpisodes)
    lazy private(set) var allCollections = Resource<[CollectionView]>(endpoint: server.allCollections)
    
    private var cachedEpisodeDetails = [String: Resource<EpisodeDetails>]()
    
    func episodeDetails(_ episodeView: EpisodeView) -> Resource<EpisodeDetails> {
        if let cached = cachedEpisodeDetails[episodeView.id] {
            return cached
        }
        let result = Resource(endpoint: server.episodeDetails(episode: episodeView))
        cachedEpisodeDetails[episodeView.id] = result
        return result
    }
}

extension CollectionView: @retroactive Equatable {
    public static func == (lhs: Model.CollectionView, rhs: Model.CollectionView) -> Bool {
        lhs.id == rhs.id
    }
}
extension EpisodeView: @retroactive Equatable {}

extension EpisodeDetails: @retroactive Equatable {
    public static func == (lhs: Model.EpisodeDetails, rhs: Model.EpisodeDetails) -> Bool {
        lhs.id == rhs.id
    }
}
