//
//  Magnification.swift
//  SwiftTalk
//
//  Created by 程東 on 12/22/25.
//

import SwiftUI


struct MagnificationItem: Identifiable {
    let index: Int
    let id = UUID()
    
    var color: Color {
        [Color.red, .orange, .green, .blue][index % 4]
    }
    
    var symbolName: String {
        ["heart.fill", "star.fill", "moon.fill", "sun.max.fill"][index % 4]
    }
}

struct MagnificationCardView: View {
    let item: MagnificationItem
    
    var body: some View {
        Image(systemName: item.symbolName)
            .font(.largeTitle)
            .bold()
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(item.color))
    }
}

extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        .init(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    static func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
        .init(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

struct MagnificationPlayground: View {
    let items = Array(0...3).map(MagnificationItem.init(index:))
    let cardSize = CGSize(width: 80, height: 100)
    
    @Namespace private var namespace
    
    @State var currentID: MagnificationItem.ID?
    @State var openingMagnification: CGFloat = 1.0
    @State var closingMagnification: CGFloat = 1.0
    @State var containerSize: CGSize = .zero
    @State var isFullScreen: Bool = false
    
    var openingFactor: CGFloat {
        (openingMagnification - 1.0) / 2.0
    }
    
    var closingFactor: CGFloat {
        (closingMagnification - 0.5) * 2.0
    }
    
    func openingSize(for item: MagnificationItem) -> CGSize {
        guard item.id == currentID else {
            return cardSize
        }
        return interpolatedSize(openingFactor)
    }
    
    func interpolatedSize(_ factor: CGFloat) -> CGSize {
        let size = cardSize + (containerSize - cardSize) * max(0, min(1, factor))
        return .init(width: max(0, size.width), height: max(0, size.height))
    }
    
    var currentItem: MagnificationItem? {
        items.first(where: { $0.id == currentID })
    }
    
    func openingGesture(for item: MagnificationItem) -> some Gesture {
        let pinch = MagnificationGesture().onChanged({ value in
            withAnimation(.interactiveSpring) {
                openingMagnification = value
                currentID = item.id
            }
        }).onEnded({ _ in
            withAnimation(.bouncy) {
                if openingMagnification > 1.5 {
                    isFullScreen = true
                } else {
                    openingMagnification = 1
                }
            }
            openingMagnification = 1
        })
        let tap = TapGesture().onEnded {
            withAnimation(.smooth) {
                currentID = item.id
                isFullScreen = true
            }
            openingMagnification = 1
        }
        return pinch.exclusively(before: tap)
    }
    
    var closingGesture: some Gesture {
        let pinch = MagnificationGesture().onChanged({ value in
            withAnimation(.interactiveSpring) {
                closingMagnification = value
            }
        }).onEnded({ _ in
            withAnimation(.bouncy) {
                if closingMagnification < 1.8 {
                    isFullScreen = false
                } else {
                    closingMagnification = 1
                }
            }
            closingMagnification = 1
        })
        let tap = TapGesture().onEnded {
            withAnimation(.smooth) {
                isFullScreen = false
            }
            closingMagnification = 1
        }
        return pinch.exclusively(before: tap)
    }
    
    var body: some View {
        ZStack {
            HStack {
                ForEach(items) { item in
                    let size = openingSize(for: item)
                    let shouldHide = isFullScreen && currentID == item.id
                    ZStack {
                        if !shouldHide {
                            MagnificationCardView(item: item)
                                .matchedGeometryEffect(id: item.id, in: namespace)
                                .frame(width: size.width, height: size.height)
                                .transition(.asymmetric(insertion: .identity, removal: .identity))
                        }
                    }
                    .frame(width: cardSize.width, height: cardSize.height)
                    .zIndex(item.id == currentID ? 2 : 1)
                    .gesture(openingGesture(for: item))
                }
            }
            if let item = currentItem, isFullScreen {
                let size = interpolatedSize(closingFactor)
                MagnificationCardView(item: item)
                    .matchedGeometryEffect(id: item.id, in: namespace)
                    .frame(width: size.width, height: size.height)
                    .transition(.asymmetric(insertion: .identity, removal: .identity))
                    .gesture(closingGesture)
            }
            Color.clear
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: {
                    containerSize = $0
                }
        }
        .padding(50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MagnificationPlayground()
}
