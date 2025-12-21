//
//  Untitled.swift
//  SwiftTalk
//
//  Created by 程東 on 12/21/25.
//

import SwiftUI

struct LabeledBar: View {
    var leftLabel: String
    var rightLabel: String
    var progress: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(leftLabel)
                Spacer()
                Text(rightLabel)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .foregroundStyle(.gray.opacity(0.3))
                    Capsule()
                        .foregroundStyle(.blue)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 10)
        }
        .padding()
    }
}

struct LabeledBar_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("System Status")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                
                LabeledBar(leftLabel: "Internal Storage", rightLabel: "45% Used", progress: 0.45)
                
                LabeledBar(leftLabel: "Uploading 'Photos.zip'", rightLabel: "1.2 GB / 2.0 GB", progress: 0.6)
                
                LabeledBar(leftLabel: "Battery Level", rightLabel: "20% (Low Power)", progress: 0.2)
                
                LabeledBar(leftLabel: "Monthly Budget", rightLabel: "$1,850 / $2,000", progress: 0.92)
                
                LabeledBar(leftLabel: "Level 14", rightLabel: "340/500 XP", progress: 0.68)
                
                LabeledBar(leftLabel: "Downloading Update", rightLabel: "Estimating...", progress: 0.05)
                
                LabeledBar(leftLabel: "Timer", rightLabel: "0:45 remaining", progress: 0.75)
                
                LabeledBar(leftLabel: "Event Capacity", rightLabel: "Sold Out", progress: 1.0)
                
                LabeledBar(leftLabel: "CPU Load", rightLabel: "99%", progress: 0.99)
                
                LabeledBar(leftLabel: "Indexing...", rightLabel: "2%", progress: 0.02)
            }
            .padding()
        }
    }
}
