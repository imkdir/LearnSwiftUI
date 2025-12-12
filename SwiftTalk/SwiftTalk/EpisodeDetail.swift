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
            oldValue.map({
                $0.seek(to: .zero)
                $0.pause()
            })
            started = false
            observation = player?.observe(\.rate, options: [.new]) {
                self.paused = ($1.newValue ?? 0) <= 0
            }
        }
    }
    
    var paused = true {
        didSet {
            if !paused {
                started = true
            }
        }
    }
    
    var started = false
    
    private var observation: NSKeyValueObservation?
}

struct EpisodeDetail: View {
    let episode: EpisodeView
    
    private let playerState = PlayerState()
    
    var player: AVPlayer? {
        playerState.player
    }
    
    var poster: Resource<UIImage> {
        Store.shared.loadPoster(of: episode)
    }

    var overlay: (some View)? {
        playerState.started ? nil : poster.value.map {
            Image(uiImage: $0)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
                playerState.player = episode.preview_url.map(AVPlayer.init(url:))
            }
            .onDisappear {
                playerState.player = nil
            }
        }
    }
}
