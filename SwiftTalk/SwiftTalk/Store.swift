//
//  Store.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import UIKit
import TinyNetworking

class Store {
    static let shared = Store()
    
    lazy private(set) var allEpisodes = Resource<[EpisodeView]>(endpoint: episodes)
    lazy private(set) var allCollections = Resource<[CollectionView]>(endpoint: collections)
    
    private(set) var cachedArtworks: [String: Resource<UIImage>] = [:]
    private(set) var cachedPosters: [String: Resource<UIImage>] = [:]
    private(set) var cachedThumbnails: [String: Resource<UIImage>] = [:]
    
    func loadArtwork(of collection: CollectionView) -> Resource<UIImage> {
        if let image = cachedArtworks[collection.id] {
            return image
        }
        let image = Resource(endpoint: .init(imageUrl: collection.artwork.png))
        cachedArtworks[collection.id] = image
        return image
    }
    
    func loadPoster(of episode: EpisodeView) -> Resource<UIImage> {
        if let image = cachedPosters[episode.id] {
            return image
        }
        let image = Resource(endpoint: .init(imageUrl: episode.poster_url))
        cachedPosters[episode.id] = image
        return image
    }
    
    func loadThumbnail(of episode: EpisodeView) -> Resource<UIImage> {
        if let image = cachedThumbnails[episode.id] {
            return image
        }
        let image = Resource(endpoint: .init(imageUrl: episode.small_poster_url))
        cachedThumbnails[episode.id] = image
        return image
    }
    
    private let collections = Endpoint<[CollectionView]>(
        json: .get,
        url: URL(string: "\(baseUrl)/collections.json")!
    )
    private let episodes = Endpoint<[EpisodeView]>(
        json: .get,
        url: URL(string: "\(baseUrl)/episodes.json")!
    )
}

private let baseUrl = "https://talk.objc.io"

struct ImageError: Error {}

extension Endpoint where A == UIImage {
    init(imageUrl url: URL) {
        self.init(.get, url: url, expectedStatusCode: expected200to300) { data, _ in
            if let data, let image = UIImage(data: data) {
                return .success(image)
            }
            return .failure(ImageError())
        }
        
    }
}
