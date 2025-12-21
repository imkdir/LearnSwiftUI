//
//  FlowLayout.swift
//  SwiftTalk
//
//  Created by 程東 on 12/14/25.
//

import SwiftUI

struct FlowLayoutSizePreferenceKey: PreferenceKey {
    static var defaultValue: [CGSize] = []
    
    static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
        value += nextValue()
    }
}

func layout(sizes: [CGSize], spacing: CGSize = .init(width: 10, height: 10)) -> [CGPoint] {
    var currentPoint: CGPoint = .zero
    var result: [CGPoint] = []
    for size in sizes {
        result.append(currentPoint)
        currentPoint.x += size.width + spacing.width
    }
    return result
}

func layout(sizes: [CGSize], spacing: CGSize = .init(width: 10, height: 10), containerWidth: CGFloat) -> [CGPoint] {
    var currentPoint: CGPoint = .zero
    var result: [CGPoint] = []
    var lineHeight: CGFloat = 0
    
    for size in sizes {
        if currentPoint.x + size.width > containerWidth {
            currentPoint.x = 0
            currentPoint.y += lineHeight + spacing.height
            lineHeight = 0
        }
        result.append(currentPoint)
        currentPoint.x += size.width + spacing.width
        lineHeight = max(lineHeight, size.height)
    }
    return result
}

struct FlowLayout<Element: Identifiable, Cell: View>: View {
    var items: [Element]
    var cell: (Element) -> Cell
    
    /* Note:
     In the previous version of this project, we also stored the IDs of items along with their sizes. It's undocumented, but the aggregated sizes seem to always be in the same order as the cells, so we can look up each cell's size by its index, and we don't need its ID.
     */
    @State private var sizes: [CGSize] = []
    
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        let laidout = layout(sizes: sizes, containerWidth: containerWidth)
        
        VStack(spacing: 0) {
            GeometryReader { proxy in
                Color.clear.preference(key: FlowLayoutSizePreferenceKey.self, value: [proxy.size])
            }
            .onPreferenceChange(FlowLayoutSizePreferenceKey.self) {
                self.containerWidth = $0[0].width
            }
            .frame(height: 0)
            ZStack(alignment: .topLeading) {
                ForEach(Array(zip(items, items.indices)), id: \.0.id) { (item, index) in
                    cell(item)
                        .fixedSize()
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(key: FlowLayoutSizePreferenceKey.self, value: [proxy.size])
                            }
                        }
                    /*
                     Before, we rendered each item at a calculated offset. But by using alignment guides instead of offsets, we let the layout system place the items, allowing the ZStack to automatically grow with its contents
                     */
                        .alignmentGuide(.leading) { dimension in
                            guard !laidout.isEmpty else { return 0 }
                            return -laidout[index].x
                        }
                        .alignmentGuide(.top) { dimension in
                            guard !laidout.isEmpty else { return 0 }
                            return -laidout[index].y
                        }
                }
            }
            .onPreferenceChange(FlowLayoutSizePreferenceKey.self) { value in
                self.sizes = value
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct Item: Identifiable, Hashable {
    let id = UUID()
    let value: String
}

private let quotes = [
    "Three may keep a secret, if two of them are dead.",
    "Early to bed and early to rise, makes a man healthy, wealthy and wise.",
    "Fish and visitors stink in three days.",
    "God helps them that help themselves.",
    "Lost time is never found again.",
    "He that lies down with dogs, shall rise up with fleas.",
    "Love your enemies, for they tell you your faults.",
    "There are no gains without pains.",
    "Well done is better than well said.",
    "Haste makes waste."
]

struct FlowLayoutPlayground: View {
    let items: [Item] = quotes
        .flatMap({ $0.components(separatedBy: " ")})
        .map(Item.init(value:))
    
    @State var spacing: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: spacing)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "arrow.forward")
                            .font(.largeTitle)
                            .bold()
                            .opacity((spacing-20)/50.0)
                    }
                ScrollView {
                    FlowLayout(items: items) { item in
                        Text(item.value)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 5).fill(.blue))
                    }
                    .border(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Text("Adjust Spacing to Trigger Layout")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Slider(value: $spacing, in: 0...200)
                .padding(.horizontal, 60)
        }
        .padding()
    }
}

#Preview {
    FlowLayoutPlayground()
}
