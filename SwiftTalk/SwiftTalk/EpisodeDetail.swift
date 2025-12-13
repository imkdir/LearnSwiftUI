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

    func connect(_ player: AVPlayer?, episode: EpisodeView) {
        observation = player?.observe(\.rate, options: [.new]) {
            self.paused = ($1.newValue ?? 0) <= 0
        }
        timeObserver = player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main, using: { time in
            self.position.send(time.seconds)
        })
        cancellable = position
            .dropFirst()
            .throttle(for: .seconds(10), scheduler: RunLoop.main, latest: true)
            .removeDuplicates()
            .sink { time in
                print("send to network \(time)")
            }
        
        if let player {
            if started {
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                player.play()
            } else {
                player.seek(to: .zero)
            }
        }
    }
    
    func disconnect(_ player: AVPlayer?, presented: Bool) {
        if let player {
            timeObserver.map(player.removeTimeObserver(_:))
            player.pause()
        }
        cancellable?.cancel()
        observation = nil
        
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
    private var cancellable: AnyCancellable?
    @ObservationIgnored
    private var observation: NSKeyValueObservation?
    @ObservationIgnored
    private var timeObserver: Any?
}

struct EpisodeDetail: View {
    let episode: EpisodeView
    let displayInCollection: Bool
    
    private let playerState = PlayerState()
    @State private var player: AVPlayer?
    @Environment(\.isPresented) private var isPresented
    @Environment(\.allCollections) private var allCollections
    
    init(episode: EpisodeView, displayInCollection: Bool = false) {
        self.episode = episode
        self.displayInCollection = displayInCollection
    }
    
    var locked: Bool {
        episode.subscription_only
    }

    var overlay: (some View) {
        AsyncImage(url: episode.poster_url) {
            $0.resizable().aspectRatio(contentMode: .fit)
                .overlay {
                    Group {
                        if let player {
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
        NavigationStack {
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
                        if let player {
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
                            VStack(alignment: .leading) {
                                Text("In Collection")
                                    .font(.headline)
                                    .padding(.top, 20)
                                AsyncImage(url: item.artwork.png) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(
                                            cornerSize: .init(width: 12, height: 12),
                                            style: .continuous
                                        ))
                                        .shadow(
                                            color: Color(uiColor: .init(white: 0, alpha: 0.1)),
                                            radius: 8
                                        )
                                        .overlay(alignment: .bottomLeading) {
                                            Text(item.title)
                                                .bold()
                                                .font(.largeTitle)
                                                .minimumScaleFactor(0.8)
                                                .lineLimit(nil)
                                                .padding()
                                                .background(Color(uiColor: .systemBackground.withAlphaComponent(0.8)))
                                                .border(.secondary)
                                                .padding()
                                        }
                                } placeholder: {
                                    Color(uiColor: .tertiarySystemBackground)
                                }
                            }
                        }).buttonStyle(.plain)
                    })
                }
                .padding()
            }
            .onAppear {
                if !playerState.started {
                    player = episode.mediaUrl.map(AVPlayer.init(url:))
                }
                playerState.connect(player, episode: episode)
            }
            .onDisappear {
                player?.pause()
                playerState.disconnect(player, presented: isPresented)
            }
        }
    }
}

extension EpisodeView {
    var mediaUrl: URL? {
        subscription_only ? preview_url : hls_url
    }

    var caption: String {
        "Episode \(number) · \(TimeInterval(media_duration).hoursAndMinutes) · \(released_at.desc)"
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
