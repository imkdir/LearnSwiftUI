//
//  EpisodeItem.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import SwiftUI
import ViewHelpers

struct EpisodeItem: View {
    let episode: EpisodeView
    
    enum Style {
        case value1
        case value2(showDivider: Bool)
    }
    var style: Style = .value1
    
    var locked: Bool {
        episode.subscription_only
    }
    
    var body: some View {
        Group {
            switch style {
            case .value1:
                VStack(alignment: .leading) {
                    Text(episode.title).font(.headline)
                    HStack {
                        AsyncImage(url: episode.small_poster_url) {
                            $0.resizable()
                                .aspectRatio(contentMode: .fit)
                                .overlay(alignment: .topLeading) {
                                    locked ? Image(systemName: "lock.square.fill")
                                        .foregroundStyle(.white)
                                        .font(.caption)
                                        .padding([.top, .leading], 2)
                                    : nil
                                }
                        } placeholder: {
                            #if os(iOS)
                            Color(uiColor: .tertiarySystemFill)
                                .frame(width: 131)
                            #else
                            Color.gray
                                .frame(width: 131)
                            #endif
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(episode.synopsis)
                                .font(.footnote)
                                .lineLimit(2)
                            Spacer()
                            Text(episode.caption2)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 60)
                }
            case .value2(let showDivider):
                VStack(alignment: .leading) {
                    Text(episode.title)
                        .font(.headline)
                    HStack(spacing: 4) {
                        locked ? Image(systemName: "lock.fill") : nil
                        Text(episode.caption2)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(episode.synopsis)
                    showDivider ? Divider() : nil
                }
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension EpisodeView {
    var caption1: String {
        "\(TimeInterval(media_duration).hoursAndMinutes) · \(released_at.pretty)"
    }
    
    var caption2: String {
        "Episode \(number) · \(released_at.pretty)"
    }
}
