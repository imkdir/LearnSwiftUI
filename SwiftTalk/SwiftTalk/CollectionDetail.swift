//
//  CollectionDetail.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import SwiftUI
import ViewHelpers

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
                                EpisodeItem(
                                    episode: item,
                                    style: .value2(showDivider: !isLastEpisode(item))
                                )
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

extension CollectionView {
    var caption: String {
        "\(episodes_count) episodes · \(TimeInterval(total_duration).hoursAndMinutes)"
    }
}

extension EpisodeView: @retroactive Comparable {
    public static func == (lhs: EpisodeView, rhs: EpisodeView) -> Bool {
        lhs.collection == rhs.collection
        && lhs.number == rhs.number
    }
    
    public static func < (lhs: Model.EpisodeView, rhs: Model.EpisodeView) -> Bool {
        lhs.number < rhs.number
    }
}
