//
//  SwiftTalk.swift
//  SwiftTalk
//
//  Created by 程東 on 12/11/25.
//

import SwiftUI
import TinyNetworking
import Model
import ViewHelpers

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

extension EnvironmentValues {
    @Entry var allEpisodes = Store.shared.allEpisodes
}

struct CollectionDetail: View {
    let collection: CollectionView
    
    @Environment(\.allEpisodes) private var allEpisodes: Resource<[EpisodeView]>
    
    var episodes: [EpisodeView] {
        allEpisodes.value.map({ items in
            items.filter({ $0.collection == collection.id })
        }) ?? []
    }
    
    func isLastEpisode(_ view: EpisodeView) -> Bool {
        episodes.max()?.number == view.number
    }
    
    var artwork: Resource<UIImage> {
        Store.shared.loadArtwork(of: collection)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(collection.title)
                        .bold()
                        .font(.largeTitle)
                        .lineLimit(2)
                        .padding()
                        .background(Color(uiColor: .systemBackground.withAlphaComponent(0.8)))
                        .border(.secondary)
                    Text(collection.description)
                        .lineLimit(nil)
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(episodes.sorted()) { item in
                            NavigationLink(destination: {
                                // TODO: episode detail view
                            }) {
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Text("Episode \(item.number) · \(item.released_at.desc)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(item.synopsis)
                                    isLastEpisode(item) ? nil : Divider()
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color(uiColor: .separator.withAlphaComponent(0.1)), radius: 8)
                    .opacity(episodes.isEmpty ? 0 : 1)
                    .animation(.easeInOut, value: episodes.isEmpty)
                }
                .padding(.horizontal)
            }
            .background(alignment: .top) {
                artwork.value.map({
                    Image(uiImage: $0)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                })
            }
        }
    }
}

struct SwiftTalk {
    var collections: [CollectionView] {
        Store.shared.allCollections.value ?? []
    }
    
    var episodes: [EpisodeView] {
        Store.shared.allEpisodes.value ?? []
    }
}

extension CollectionView {
    var caption: String {
        "\(episodes_count) episodes · \(TimeInterval(total_duration).hoursAndMinutes)"
    }
}

extension EpisodeView {
    var caption: String {
        "\(TimeInterval(media_duration).hoursAndMinutes) · \(released_at.desc)"
    }
}

struct EpisodeItem: View {
    let episode: EpisodeView
    
    var thumbnail: Resource<UIImage> {
        Store.shared.loadThumbnail(of: episode)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Group {
                if let image = thumbnail.value {
                    Image(uiImage: image)
                        .resizable()
                } else {
                    Rectangle()
                        .fill(Color(uiColor: .tertiarySystemFill))
                }
            }
            .frame(width: 147.5, height: 67.5)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading) {
                Text(episode.title)
                    .font(.headline)
                Text(episode.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension SwiftTalk: View {
    var body: some View {
        TabView {
            Tab("Collections", systemImage: "rectangle.grid.2x2") {
                NavigationStack {
                    List {
                        ForEach(collections) { col in
                            NavigationLink(destination: {
                                CollectionDetail(collection: col)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(col.title)
                                        .font(.headline)
                                    Text(col.caption)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle("Collections")
                }
            }
            Tab("Episodes", systemImage: "rectangle.grid.1x2") {
                NavigationStack {
                    List {
                        ForEach(episodes) { epi in
                            NavigationLink(destination: {
                                // TODO: episodes detail
                            }) {
                                EpisodeItem(episode: epi)
                            }
                        }
                    }
                    .navigationTitle("Episodes")
                }
            }
        }
    }
}

extension CollectionView: @retroactive Identifiable {}
extension EpisodeView: @retroactive Identifiable {}

extension EpisodeView: @retroactive Comparable {
    public static func == (lhs: EpisodeView, rhs: EpisodeView) -> Bool {
        lhs.collection == rhs.collection
        && lhs.number == rhs.number
    }
    
    public static func < (lhs: Model.EpisodeView, rhs: Model.EpisodeView) -> Bool {
        lhs.number < rhs.number
    }
}


#Preview {
    SwiftTalk()
}
