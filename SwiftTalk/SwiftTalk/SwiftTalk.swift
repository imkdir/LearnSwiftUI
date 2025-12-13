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
    @Entry var allCollections = Store.shared.allCollections
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
                        ForEach(collections) { item in
                            NavigationLink(destination: {
                                CollectionDetail(collection: item)
                            }) {
                                CollectionItem(collection: item)
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
                                EpisodeDetail(episode: item, displayInCollection: true)
                            }) {
                                EpisodeItem(episode: item)
                            }
                        }
                    }
                    .navigationTitle("Episodes")
                }
            }
            Tab("Account", systemImage: "person.fill") {
                NavigationStack {
                    Account()
                        .navigationTitle("Account")
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
