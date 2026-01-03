//
//  FlowLayout.swift
//  SwiftTalk
//
//  Created by 程東 on 12/14/25.
//

import SwiftUI

struct FlowLayout: Layout {
    let alignment: VerticalAlignment
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal
            .replacingUnspecifiedDimensions().width
        let dimensions = subviews
            .map({ $0.dimensions(in: .unspecified) })
        
        let (_, size) = layout(
            dimensions: dimensions,
            containerWidth: containerWidth,
            alignment: alignment
        )
        
        return size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        let dimensions = subviews
            .map({ $0.dimensions(in: .unspecified) })
        
        let (offsets, _) = layout(
            dimensions: dimensions,
            containerWidth: bounds.width,
            alignment: alignment
        )
        
        zip(subviews, offsets).forEach { subview, offset in
            subview.place(at: offset, proposal: proposal)
        }
    }
}

private func layout(dimensions: [ViewDimensions], spacing: CGSize = .init(width: 10, height: 10), containerWidth: CGFloat, alignment: VerticalAlignment) -> (offsets: [CGPoint], containerSize: CGSize) {
    var result: [CGRect] = []
    var currentPosition: CGPoint = .zero
    var currentLine: [CGRect] = []
    
    func flushLine() {
        currentPosition.x = 0
        let union = currentLine.union
        result += currentLine.map({ rect in
            var copy = rect
            copy.origin.y += currentPosition.y - union.minY
            return copy
        })
        currentPosition.y += union.height + spacing.height
        currentLine.removeAll()
    }
    
    for dim in dimensions {
        if currentPosition.x + dim.width > containerWidth {
            flushLine()
        }
        currentLine.append(.init(x: currentPosition.x, y: -dim[alignment], width: dim.width, height: dim.height))
        currentPosition.x += dim.width + spacing.width
    }
    
    flushLine()
    
    return (result.map({ $0.origin }), result.union.size)
}

extension Sequence where Element == CGRect {
    var union: CGRect {
        reduce(.null, { $0.union($1) })
    }
}

enum Align: String, Identifiable, CaseIterable, View {
    case top, center, bottom, firstTextBaseline, lastTextBaseline
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .top:
            "align.vertical.top"
        case .center:
            "align.vertical.center"
        case .bottom:
            "align.vertical.bottom"
        case .firstTextBaseline:
            "text.line.first.and.arrowtriangle.forward"
        case .lastTextBaseline:
            "text.line.last.and.arrowtriangle.forward"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(rawValue)
        }
    }
    
    var alignment: VerticalAlignment {
        switch self {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        case .firstTextBaseline: .firstTextBaseline
        case .lastTextBaseline: .lastTextBaseline
        }
    }
}

struct FlowLayoutPlayground: View {
    let items: [Item] = quotes.map(Item.init(value:))
    
    @State private var spacing: CGFloat = 0
    @State private var align: Align = .top
    
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
                    FlowLayout(alignment: align.alignment) {
                        ForEach(items) {
                            $0
                        }
                    }
                    .animation(.default, value: align)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text("Adjust Spacing to Trigger Layout")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Slider(value: $spacing, in: 0...200)
                .padding(.horizontal, 60)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Picker", selection: $align) {
                        ForEach(Align.allCases) {
                            $0
                        }
                    }
                } label: {
                    Image(systemName: align.icon)
                        .font(.footnote)
                }
            }
        }
    }
}

struct Item: Identifiable, View {
    let id = UUID()
    let value: String
    let top = Int.random(in: 4...16)
    let bottom = Int.random(in: 4...16)
    
    var contentInset: EdgeInsets {
        .init(
            top: CGFloat(top),
            leading: 6,
            bottom: CGFloat(bottom),
            trailing: 6
        )
    }
    
    var body: some View {
        Text(value)
            .foregroundStyle(.white)
            .padding(contentInset)
            .background(RoundedRectangle(cornerRadius: 6).fill(.blue))
    }
}

private let quotes = [
    "Three may keep a secret", "if", "two", "of", "them", "are", "dead.",
    "Fish and visitors", "stink", "in three days.",
    "There are no gains \nwithout pains.",
    "Haste", "makes", "waste"
]

#Preview {
    NavigationStack {
        FlowLayoutPlayground()
    }
}
