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

extension EnvironmentValues {
    @Entry var allEpisodes = Store.shared.allEpisodes
}

struct SwiftTalk {
    var collections: [CollectionView] {
        Store.shared.allCollections.value ?? []
    }
    
    var episodes: [EpisodeView] {
        Store.shared.allEpisodes.value ?? []
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
                        ForEach(episodes) { item in
                            NavigationLink(destination: {
                                // TODO: episodes detail
                            }) {
                                EpisodeItem(episode: item)
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


#Preview {
    SwiftTalk()
}
