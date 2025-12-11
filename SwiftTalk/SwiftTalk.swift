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
private let collections = Endpoint<[CollectionView]>(
    json: .get,
    url: URL(string: "\(baseUrl)/collections.json")!
)
private let episodes = Endpoint<[EpisodeView]>(
    json: .get,
    url: URL(string: "\(baseUrl)/episodes.json")!
)

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

extension CollectionView {
    var artworkEndpoint: Endpoint<UIImage> {
        .init(imageUrl: artwork.png)
    }
}

class Store {
    static let shared = Store()
    
    lazy private(set) var allEpisodes = Resource<[EpisodeView]>(endpoint: episodes)
    lazy private(set) var allCollections = Resource<[CollectionView]>(endpoint: collections)
    
    private(set) var cachedImages: [String: Resource<UIImage>] = [:]
    
    func loadImage(of collection: CollectionView) -> Resource<UIImage> {
        if let image = cachedImages[collection.id] {
            return image
        }
        let image = Resource(endpoint: collection.artworkEndpoint)
        cachedImages[collection.id] = image
        return image
    }
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
        Store.shared.loadImage(of: collection)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    artwork.value.map({
                        Image(uiImage: $0)
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    })
                    Spacer()
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(collection.title)
                            .bold()
                            .font(.largeTitle)
                            .lineLimit(2)
                            .shadow(radius: 0, x: 2, y: 2)
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
                                            .bold()
                                        Text("Episode \(item.number)")
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
                .background(Color.clear)
            }
        }
    }
}

struct SwiftTalk {
    
    private let allCollections = Resource(endpoint: collections)
    
    var data: [CollectionView] {
        allCollections.value ?? []
    }
}

extension CollectionView {
    var caption: String {
        "\(episodes_count) episodes · \(TimeInterval(total_duration).hoursAndMinutes)"
    }
}

extension SwiftTalk: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(data) { datum in
                    NavigationLink(destination: {
                        CollectionDetail(collection: datum)
                    }) {
                        VStack(alignment: .leading) {
                            Text(datum.title)
                            Text(datum.caption)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Collections")
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
