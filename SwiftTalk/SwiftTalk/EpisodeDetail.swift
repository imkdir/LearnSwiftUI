//
//  EpisodeDetail.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import AVKit
import SwiftUI
import ViewHelpers

@Observable
class PlayerState {
    
    var player: AVPlayer? {
        didSet {
            oldValue.map({ p in
                p.seek(to: .zero)
                p.pause()
                timeObserver.map(p.removeTimeObserver(_:))
            })
            position = 0
            started = false
            observation = player?.observe(\.rate, options: [.new]) {
                self.paused = ($1.newValue ?? 0) <= 0
            }
            timeObserver = player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main, using: { time in
                self.position = time.seconds
            })
        }
    }
    
    var paused = true {
        didSet {
            if !paused {
                started = true
            }
        }
    }
    
    var position: TimeInterval = 0 {
        didSet {
            print(position)
        }
    }
    
    var started = false
    
    private var observation: NSKeyValueObservation?
    private var timeObserver: Any?
}

struct EpisodeDetail: View {
    let episode: EpisodeView
    
    private let playerState = PlayerState()
    
    var player: AVPlayer? {
        playerState.player
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
                playerState.player = episode.mediaUrl.map(AVPlayer.init(url:))
            }
            .onDisappear {
                playerState.player = nil
            }
        }
    }
}

extension EpisodeView {
    var mediaUrl: URL? {
        subscription_only ? preview_url : hls_url
    }
}
