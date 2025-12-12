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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(collection.title)
                .font(.headline)
            Text(collection.caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

extension CollectionView {
    var caption: String {
        "\(episodes_count) episodes · \(TimeInterval(total_duration).hoursAndMinutes)"
    }
}
