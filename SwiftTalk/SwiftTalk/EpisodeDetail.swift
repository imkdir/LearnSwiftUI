//
//  EpisodeDetail.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import AVKit
import Combine
import Observation
import SwiftUI
import ViewHelpers

@Observable
class PlayerState {
    
    private(set) var player: AVPlayer?
    
    func connect(episode: EpisodeView) {
        Store.shared
            .episodeDetails(episode)
            .valueSubject
            .removeDuplicates()
            .sink { [weak self] details in
                guard let self else { return }
                if !self.started {
                    let mediaUrl = details?.hls_url ?? episode.mediaUrl
                    self.player = mediaUrl.map(AVPlayer.init(url:))
                }
                self.connect(self.player)
            }.store(in: &cancellables)
    }
    
    private func connect(_ player: AVPlayer?) {
        observation = player?.observe(\.rate, options: [.new]) {
            self.paused = ($1.newValue ?? 0) <= 0
        }
        timeObserver = player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main, using: { time in
            self.position.send(time.seconds)
        })
        position
            .dropFirst()
            .throttle(for: .seconds(10), scheduler: RunLoop.main, latest: true)
            .removeDuplicates()
            .sink { time in
                print("send to network \(time)")
            }.store(in: &cancellables)
        
        if let player {
            if started {
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                player.play()
            } else {
                player.seek(to: .zero)
            }
        }
    }
    
    func disconnect(presented: Bool) {
        cancellables.removeAll()
        
        if let player {
            timeObserver.map(player.removeTimeObserver(_:))
            player.pause()
        }
        
        if !presented {
            started = false
        }
    }
    
    var paused = true {
        didSet {
            if !paused {
                started = true
            }
        }
    }
    
    private var time: CMTime {
        .init(seconds: position.value, preferredTimescale: 1)
    }
    
    var started = false
    
    @ObservationIgnored
    private let position = CurrentValueSubject<TimeInterval, Never>(0)
    
    @ObservationIgnored
    private var cancellables: Set<AnyCancellable> = []
    @ObservationIgnored
    private var observation: NSKeyValueObservation?
    @ObservationIgnored
    private var timeObserver: Any?
}

struct EpisodeDetail: View {
    let episode: EpisodeView
    let displayInCollection: Bool
    
    @State private var playerState = PlayerState()
    private let finishedEpisodes = FinishedEpisodes.shared
    
    @Environment(\.isPresented) private var isPresented
    @Environment(\.allCollections) private var allCollections
    
    init(episode: EpisodeView, displayInCollection: Bool = false) {
        self.episode = episode
        self.displayInCollection = displayInCollection
    }
    
    var details: EpisodeDetails? {
        Store.shared.episodeDetails(episode).value
    }
    
    var locked: Bool {
        episode.subscription_only && details == nil
    }
    
    var overlay: (some View) {
        AsyncImage(url: episode.poster_url) {
            $0.resizable().aspectRatio(contentMode: .fit)
                .overlay {
                    Group {
                        if let player = playerState.player {
                            Button {
                                player.play()
                            } label: {
                                ZStack {
                                    Color.clear
                                        .overlay(alignment: .topLeading) {
                                            locked ? PreviewBadge() : nil
                                        }
                                    Image(systemName: "play.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(Color.white)
                                }
                            }
                        } else {
                            Color.clear
                        }
                    }
                }
        } placeholder: {
            Color.clear
        }
    }
    
    var collection: CollectionView? {
        guard displayInCollection else {
            return nil
        }
        return allCollections.value.flatMap({
            $0.first(where: { $0.id == episode.collection })
        })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(episode.title)
                    .font(.largeTitle)
                    .bold()
                    .lineLimit(nil)
                Text(episode.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(episode.synopsis)
                    .lineLimit(nil)
                    .padding(.vertical, 8)
                Group {
                    if let player = playerState.player {
                        VideoPlayer(player: player) {
                            playerState.started ? nil : overlay
                        }
                    } else {
                        overlay
                    }
                }.aspectRatio(16/9, contentMode: .fit)
                collection.map({ item in
                    NavigationLink(destination: {
                        CollectionDetail(collection: item)
                    }, label: {
                        CollectionCard(collection: item)
                    }).buttonStyle(.plain)
                })
            }
            .padding()
            .toolbar {
                ToolbarItem {
                    Button {
                        finishedEpisodes.toggle(episode)
                    } label: {
                        Image(systemName: finishedEpisodes.isFinished(episode) ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                }
            }
        }
        .onAppear {
            playerState.connect(episode: episode)
        }
        .onDisappear {
            playerState.disconnect(presented: isPresented)
        }
    }
}

extension EpisodeView {
    var mediaUrl: URL? {
        subscription_only ? preview_url : hls_url
    }
    
    var caption: String {
        "Episode \(number) · \(TimeInterval(media_duration).hoursAndMinutes) · \(released_at.pretty)"
    }
}

struct CollectionCard: View {
    let collection: CollectionView
    
    var body: some View {
        AsyncImage(url: collection.artwork.png) { image in
            VStack(alignment: .leading) {
                Text("In Collection")
                    .font(.headline)
                    .padding(.top, 20)
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #if os(iOS)
                    .background(Color(uiColor: .systemBackground))
                #else
                    .background(Color(nsColor: .windowBackgroundColor))
                #endif
                    .clipShape(RoundedRectangle(
                        cornerSize: .init(width: 12, height: 12),
                        style: .continuous
                    ))
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 8
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text(collection.title)
                            .bold()
                            .font(.largeTitle)
                            .minimumScaleFactor(0.8)
                            .lineLimit(nil)
                            .padding()
                            .background(.background.opacity(0.8))
                            .border(.secondary)
                            .padding()
                    }
            }
        } placeholder: {
            #if os(iOS)
            Color(uiColor: .tertiarySystemBackground)
            #else
            Color(nsColor: .underPageBackgroundColor)
            #endif
        }
    }
}

struct BadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addLines([
                rect.origin,
                .init(x: rect.maxX, y: rect.origin.y),
                .init(x: rect.origin.x, y: rect.maxY)
            ])
            p.closeSubpath()
        }
    }
}

struct PreviewBadge: View {
    var body: some View {
        ZStack {
            BadgeShape()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.orange)
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 30)
                .rotationEffect(.init(degrees: -45))
        }
    }
}
