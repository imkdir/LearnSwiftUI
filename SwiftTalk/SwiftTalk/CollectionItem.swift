//
//  CollectionItem.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import Model
import SwiftUI
import ViewHelpers

struct CollectionItem: View {
    let collection: CollectionView
    
    private let finishedEpisodes = FinishedEpisodes.shared
    
    @Environment(\.allEpisodes) private var allEpisodes
    
    private var matchingEpisodes: [EpisodeView] {
        allEpisodes.value?.filter({ $0.collection == collection.id }) ?? []
    }
    
    private var progress: String? {
        let count = finishedEpisodes.countFinished(in: matchingEpisodes)
        guard count > 0 else {
            return nil
        }
        let totalCount = matchingEpisodes.count
        return "\(totalCount - count) remaining"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(collection.title)
                    .font(.headline)
                Text(collection.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            progress.map {
                Text($0)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

extension CollectionView {
    var caption: String {
        "\(episodes_count) episodes · \(TimeInterval(total_duration).hoursAndMinutes)"
    }
}
