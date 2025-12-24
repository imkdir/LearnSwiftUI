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
    @ObservedObject private var session = Session.shared
    @State private var showLogOutAlert = false
    @State private var searchText = ""
    
    @Environment(\.allEpisodes) private var allEpisodes
    @Environment(\.allCollections) private var allCollections

    var collections: [CollectionView] {
        allCollections.value ?? []
    }
    
    var episodes: [EpisodeView] {
        allEpisodes.value ?? []
    }
    
    var filteredEpisodes: [EpisodeView] {
        if searchText.isEmpty {
            return episodes
        } else {
            return episodes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.synopsis.localizedCaseInsensitiveContains(searchText)
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
                       ForEach(collections) { item in
                           NavigationLink(value: item) {
                               CollectionItem(collection: item)
                           }
                       }
                   }
                   .navigationTitle("Collections")
                   .navigationDestination(for: CollectionView.self) { collection in
                       CollectionDetail(collection: collection)
                   }
                   .navigationDestination(for: EpisodeView.self) { episode in
                       EpisodeDetail(episode: episode)
                   }
                   .toolbar {
                       ToolbarItem(placement: .primaryAction) {
                           if session.credentials == nil {
                               Button {
                                   session.startAuthSession()
                               } label: {
                                   Image(systemName: "person.crop.circle.dashed")
                               }
                           } else {
                               Button {
                                   showLogOutAlert = true
                               } label: {
                                   Image(systemName: "person.crop.circle.fill")
                               }.alert("Log Out", isPresented: $showLogOutAlert) {
                                   Button("Log Out", role: .destructive) {
                                       session.credentials = nil
                                   }
                                   Button("Cancel", role: .cancel) { }
                               } message: {
                                   Text("Are you sure you want to log out?")
                               }
                           }
                       }
                   }
               }
            }
            Tab("Episodes", systemImage: "rectangle.grid.1x2") {
                NavigationStack {
                    List {
                        ForEach(filteredEpisodes) { item in
                            NavigationLink(value: item) {
                                EpisodeItem(episode: item)
                            }
                        }
                    }
                    .navigationTitle("Episodes")
                    .searchable(text: $searchText, prompt: "Search Episodes")
                    .navigationDestination(for: EpisodeView.self) { episode in
                        EpisodeDetail(episode: episode, displayInCollection: true)
                    }
                }
            }
            Tab("Practices", systemImage: "square.stack.3d.up") {
                PracticeList()
            }
        }
    }
}

extension CollectionView: @retroactive Hashable, @retroactive Identifiable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension EpisodeView: @retroactive Hashable, @retroactive Identifiable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



#Preview {
    SwiftTalk()
}
