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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(collection.title)
                    .bold()
                    .font(.largeTitle)
                    .lineLimit(2)
                    .padding()
                    .background(.background.opacity(0.8))
                    .border(.secondary)
                Text(collection.description)
                    .lineLimit(nil)
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(episodes.sorted()) { item in
                        NavigationLink(value: item) {
                            EpisodeItem(
                                episode: item,
                                style: .value2(showDivider: !isLastEpisode(item))
                            )
                        }.buttonStyle(.plain)
                    }
                }
                .padding()
#if os(iOS)
                .background(
                    Color(uiColor: .systemGroupedBackground)
                )
#endif
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(episodes.isEmpty ? 0 : 1)
                .animation(.easeInOut, value: episodes.isEmpty)
            }
            .padding(.horizontal)
        }
        .background(alignment: .top) {
            AsyncImage(url: collection.artwork.png) {
                $0.resizable().scaledToFit().ignoresSafeArea()
            } placeholder: {
                Color.clear
            }
        }
    }
}

extension EpisodeView: @retroactive Comparable {
    public static func < (lhs: Model.EpisodeView, rhs: Model.EpisodeView) -> Bool {
        lhs.number < rhs.number
    }
}
