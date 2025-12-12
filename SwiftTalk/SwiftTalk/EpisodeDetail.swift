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
    
    let position = CurrentValueSubject<TimeInterval, Never>(0)
    
    var time: CMTime {
        .init(seconds: position.value, preferredTimescale: 1)
    }
    
    var started = false
    
    @ObservationIgnored
    private var cancellable: AnyCancellable?
    @ObservationIgnored
    private var observation: NSKeyValueObservation?
    @ObservationIgnored
    private var timeObserver: Any?
}

struct EpisodeDetail: View {
    let episode: EpisodeView
    
    private let playerState = PlayerState()
    @State private var player: AVPlayer?
    @Environment(\.isPresented) private var isPresented
    
    init(episode: EpisodeView) {
        self.episode = episode
    }

    var overlay: (some View)? {
        playerState.started ? nil : AsyncImage(url: episode.poster_url) {
            $0.resizable().aspectRatio(contentMode: .fit)
        } placeholder: {
            Color.clear
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(episode.title)
                    .font(.largeTitle)
                    .bold()
                    .lineLimit(nil)
                Text(episode.caption2)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(episode.synopsis)
                    .lineLimit(nil)
                    .padding(.vertical, 8)
                player.map({ player in
                    VideoPlayer(player: player) {
                        overlay
                    }.aspectRatio(16/9, contentMode: .fit)
                })
            }
            .padding()
            .onAppear {
                player = episode.mediaUrl.map(AVPlayer.init(url:))
                playerState.connect(player, episode: episode)
                
                if playerState.started {
                    player?.seek(to: playerState.time, toleranceBefore: .zero, toleranceAfter: .zero)
                }
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
}
