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
    
    var title: String {
        ["A", "B", "C", "D"][index % 4]
    }
}

struct MagnificationCardView: View {
    let item: MagnificationItem
    
    var body: some View {
        Text(item.title)
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
    @State var magnification: CGFloat = 1.0
    @State var containerSize: CGSize = .zero
    @State var isFullScreen: Bool = false
    
    var factor: CGFloat {
        max(0, magnification - 1) / 2.0
    }
    
    func getSize(for id: MagnificationItem.ID) -> CGSize {
        guard id == currentID else { return cardSize }
        let size = cardSize + (containerSize - cardSize) * factor
        return .init(width: max(0, size.width), height: max(0, size.height))
    }
    
    var currentItem: MagnificationItem? {
        items.first(where: { $0.id == currentID })
    }
    
    var body: some View {
        ZStack {
            HStack {
                ForEach(items) { item in
                    let size = getSize(for: item.id)
                    ZStack {
                        if !isFullScreen || currentID != item.id {
                            MagnificationCardView(item: item)
                                .matchedGeometryEffect(id: item.id, in: namespace)
                                .frame(width: size.width, height: size.height)
                        }
                    }
                    .frame(width: cardSize.width, height: cardSize.height)
                    .zIndex(item.id == currentID ? 2 : 1)
                    .gesture(MagnificationGesture().onChanged({ value in
                        withAnimation(.interactiveSpring) {
                            self.magnification = value
                            self.currentID = item.id
                        }
                    }).onEnded({ _ in
                        withAnimation(.bouncy) {
                            self.isFullScreen = true
                            self.magnification = 1
                        }
                    }))
                }
            }
            if let item = currentItem, isFullScreen {
                MagnificationCardView(item: item)
                    .matchedGeometryEffect(id: item.id, in: namespace)
                    .transition(.identity)
                    .onTapGesture {
                        isFullScreen = false
                    }
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
