//
//  FlowLayout.swift
//  SwiftTalk
//
//  Created by 程東 on 12/14/25.
//

import SwiftUI

struct SwiftUICollectionViewSizeKey<ID: Hashable>: PreferenceKey {
    static var defaultValue: [ID: CGSize] { [:] }
    static func reduce(value: inout [ID: CGSize], nextValue: () -> [ID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PropagateSize<V: View, ID: Hashable>: View {
    let content: V
    let id: ID
    
    var body: some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: SwiftUICollectionViewSizeKey.self,
                            value: [id: proxy.size]
                        )
                }
            }
    }
}

struct FLowLayout {
    let spacing: UIOffset
    let containerSize: CGSize
    
    init(containerSize: CGSize, spacing: UIOffset = .init(horizontal: 10, vertical: 10)) {
        self.containerSize = containerSize
        self.spacing = spacing
    }
    
    var currentX = CGFloat(0)
    var currentY = CGFloat(0)
    var lineHeight = CGFloat(0)
    
    mutating func add(element size: CGSize) -> CGRect {
        if currentX + size.width > containerSize.width {
            currentX = 0
            currentY += lineHeight + spacing.vertical
            lineHeight = 0
        }
        defer {
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing.horizontal
        }
        return CGRect(origin: .init(x: currentX, y: currentY), size: size)
    }
    
    var size: CGSize {
        .init(width: containerSize.width, height: currentY + lineHeight)
    }
}

struct CollectionLayoutView<Elements: RandomAccessCollection, Content: View>: View where Elements.Element: Identifiable {
    typealias ID = Elements.Element.ID
    typealias Layout = (Elements, CGSize, [ID: CGSize]) -> [ID: CGSize]
    
    let data: Elements
    let content: (Elements.Element) -> Content
    let layout: Layout
    
    @State private var sizes: [ID: CGSize] = [:]
    @State private var containerSize: CGSize = .zero
    
    var offsets: [ID: CGSize] {
        layout(data, containerSize, sizes)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data) {
                PropagateSize(content: content($0), id: $0.id)
                    .offset(offsets[$0.id, default: .zero])
                    .animation(.default, value: offsets)
            }
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.onPreferenceChange(SwiftUICollectionViewSizeKey<ID>.self) {
            sizes = $0
        }
        .padding()
        .border(Color.red)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            containerSize = newValue
        }
    }
}

struct FlowLayoutPlayground: View {
    
    @State private var dividerWidth: CGFloat = 0
    @State private var contentWidth: CGFloat = 60
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Color(uiColor: .tertiarySystemBackground)
                    .frame(width: dividerWidth)
                ScrollView {
                    CollectionLayoutView(data: poorRichardQuotes) {
                        Text($0.value)
                            .foregroundStyle($0.color)
                            .padding(2)
                            .border(Color.secondary)
                    } layout: { elements, containerSize, sizes in
                        var state = FLowLayout(containerSize: containerSize)
                        var result: [Words.ID: CGSize] = [:]
                        for element in elements {
                            let rect = state.add(element: sizes[element.id, default: .zero])
                            result[element.id] = .init(width: rect.origin.x, height: rect.origin.y)
                        }
                        return result
                    }
                }
                .padding(2)
                .border(Color.secondary)
            }
            Slider(value: $dividerWidth, in: 0...contentWidth-60)
                .padding(60)
        }.onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            self.contentWidth = max(60, newValue)
        }
    }
}

struct Words: Identifiable {
    let id = UUID()
    
    let value: String
    
    var color: Color {
        Color.fromString(value)
    }
}

private let poorRichardQuotes: [Words] = [
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
].flatMap({ $0.components(separatedBy: " ") }).map(Words.init(value:))

extension Color {
    static func fromString(_ value: String) -> Color {
        let hash = value.hashValue
        let hue = Double(abs(hash) % 1000) / 1000.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}
