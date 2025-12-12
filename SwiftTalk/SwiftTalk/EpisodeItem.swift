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
    
    var thumbnail: Resource<UIImage> {
        Store.shared.loadThumbnail(of: episode)
    }
    
    var body: some View {
        Group {
            switch style {
            case .value1:
                HStack(alignment: .top) {
                    Group {
                        if let image = thumbnail.value {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color(uiColor: .tertiarySystemFill))
                        }
                    }
                    .frame(width: 130, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading) {
                        Text(episode.title)
                            .font(.headline)
                        Text(episode.caption1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            case .value2(let showDivider):
                VStack(alignment: .leading) {
                    Text(episode.title)
                        .font(.headline)
                    Text(episode.caption2)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(episode.synopsis)
                    showDivider ? Divider() : nil
                }
            }
        }
    }
}

extension EpisodeView {
    var caption1: String {
        "\(TimeInterval(media_duration).hoursAndMinutes) · \(released_at.desc)"
    }
    
    var caption2: String {
        "Episode \(number) · \(released_at.desc)"
    }
}
