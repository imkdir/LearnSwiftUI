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

struct DragState<ID: Hashable> {
    let id: ID
    var translation: CGSize
    var location: CGPoint
}

struct CollectionLayoutView<Collection: RandomAccessCollection, Content: View>: View where Collection.Element: Identifiable {
    typealias Element = Collection.Element
    typealias ID = Element.ID
    typealias Layout = (Collection, CGSize, [ID: CGSize]) -> [ID: CGSize]
    
    let data: Collection
    let content: (Element) -> Content
    let layout: Layout
    let didMove: (Collection.Index, Collection.Index) -> Void
    
    @State private var sizes: [ID: CGSize] = [:]
    @State private var containerSize: CGSize = .zero
    @State private var dragState: DragState<ID>?
    
    var offsets: [ID: CGSize] {
        layout(data, containerSize, sizes)
    }
    
    func offset(of element: Element) -> CGSize {
        var offset = offsets[element.id, default: .zero]
        if let dragState, dragState.id == element.id {
            offset += dragState.translation
        }
        return offset
    }
    
    var insertion: (key: ID, value: CGSize)? {
        guard let location = dragState?.location else {
            return nil
        }
        return offsets
            .sorted(by: {
                let (lhs, rhs) = ($0.value, $1.value)
                return lhs.height > rhs.height
                    || lhs.height == rhs.height && lhs.width > rhs.width
            })
            .first(where: { (_, value) in
                value.width < location.x && value.height < location.y
            })
    }
    
    func cursor(at insertion: (key: ID, value: CGSize)) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 4, height: sizes[insertion.key]?.height)
            .offset(insertion.value)
            .offset(x: -7)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data) { datum in
                PropagateSize(content: content(datum), id: datum.id)
                    .offset(offset(of: datum))
                    .animation(.default, value: offsets)
                    .gesture(DragGesture().onChanged({ value in
                        dragState = .init(
                            id: datum.id,
                            translation: value.translation,
                            location: value.location
                        )
                    }).onEnded({ _ in
                        guard let dragState else { return }
                        
                        if let insertion,
                           let oldIdx = data.firstIndex(where: { $0.id == dragState.id }),
                           let newIdx = data.firstIndex(where: { $0.id == insertion.key }) {
                            self.dragState = nil
                            didMove(oldIdx, newIdx)
                        } else {
                            withAnimation(.bouncy) {
                                self.dragState = nil
                            }
                        }
                    }))
                if let insertion {
                    cursor(at: insertion)
                }
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
    @State private var items = poorRichardQuotes
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Color(uiColor: .tertiarySystemBackground)
                    .frame(width: dividerWidth)
                ScrollView {
                    CollectionLayoutView(data: items) {
                        $0
                    } layout: { elements, containerSize, sizes in
                        var state = FLowLayout(containerSize: containerSize)
                        var result: [Bubble.ID: CGSize] = [:]
                        for element in elements {
                            let rect = state.add(element: sizes[element.id, default: .zero])
                            result[element.id] = .init(width: rect.origin.x, height: rect.origin.y)
                        }
                        return result
                    } didMove: { oldIdx, newIdx in
                        items.move(fromOffsets: .init(integer: oldIdx), toOffset: newIdx)
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

struct Bubble: Identifiable, View {
    let id = UUID()
    
    let value: String
    
    var body: some View {
        Text(value)
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.blue)
            }
    }
}

private let poorRichardQuotes: [Bubble] = [
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
].flatMap({ $0.components(separatedBy: " ") }).map(Bubble.init(value:))

extension Color {
    static func fromString(_ value: String) -> Color {
        let hash = value.hashValue
        let hue = Double(abs(hash) % 1000) / 1000.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func += (lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs + rhs
    }
}
