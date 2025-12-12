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
