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
    
    var body: some View {
        Group {
            switch style {
            case .value1:
                HStack(alignment: .top) {
                    AsyncImage(url: episode.small_poster_url) {
                        $0.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color(uiColor: .tertiarySystemFill))
                    }
                    .frame(width: 130, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading) {
                        Text(episode.title)
                            .font(.headline)
                        Caption(
                            content: episode.caption1,
                            locked: episode.subscription_only
                        )
                    }
                }
            case .value2(let showDivider):
                VStack(alignment: .leading) {
                    Text(episode.title).font(.headline)
                    Caption(
                        content: episode.caption2,
                        locked: episode.subscription_only
                    )
                    Text(episode.synopsis)
                    showDivider ? Divider() : nil
                }
            }
        }
    }
}

struct Caption: View {
    let content: String
    let locked: Bool
    
    @State private var captionHeight = CGFloat.zero
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            locked
                ? Image(systemName: "lock.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.init(top: 2, leading: 0, bottom: 2, trailing: 2))
                    .frame(maxHeight: captionHeight)
                : nil
            Text(content)
                .font(.caption)
                .overlay {
                    GeometryReader { proxy in
                        Color.clear.onAppear {
                            self.captionHeight = proxy.frame(in: .local).size.height
                        }
                    }
                }
        }.foregroundStyle(.secondary)
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
