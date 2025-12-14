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
                   .overlay {
                       if collections.isEmpty {
                           LoadingIndicator()
                       }
                   }
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
                    .overlay {
                        if collections.isEmpty {
                            LoadingIndicator()
                        }
                    }
                }
            }
            Tab("Practices", systemImage: "square.stack.3d.up") {
                NavigationStack {
                    LoadingIndicator()
                        .navigationTitle("Practices")
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
