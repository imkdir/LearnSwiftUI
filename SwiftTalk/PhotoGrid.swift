//
//  PhotoGrid.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/29/25.
//

import SwiftUI

struct PhotoGrid: View {
    @State private var slowAnimation: Bool = true
    @State private var detail: Int?
    @Namespace private var grid
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                    ForEach(1..<11) { idx in
                        let opacity = gridOpacity(atIndex: idx)
                        Image("beach_\(idx)")
                            .resizable()
                            .matchedGeometryEffect(id: idx.description, in: grid, isSource: detail == nil)
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture {
                                detail = idx
                            }
                            .opacity(opacity)
                            .animation(.default.speed(speed), value: opacity == 0)
                    }
                }
            }
            if let detail {
                Image("beach_\(detail)")
                    .resizable()
                    .matchedGeometryEffect(id: detail.description, in: grid)
                    .aspectRatio(contentMode: .fit)
                    .offset(offset)
                    .scaleEffect(dragScale)
                    .animation(.spring.speed(speed), value: offset == .zero)
                    .gesture(detailGesture)
                    .id(detail)
            }
        }
        .animation(.default.speed(speed), value: detail)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    slowAnimation.toggle()
                } label: {
                    Image(systemName: slowAnimation ? "tortoise": "hare")
                }
            }
        }
        .navigationTitle("Photos")
    }
    
    private var speed: Double {
        slowAnimation ? 0.2 : 1.0
    }
    
    @GestureState private var offset: CGSize = .zero
    
    private var dragScale: Double {
        guard offset.height > 0 else { return 1.0 }
        return 1.0 - offset.height / 1000.0
    }
    
    private func gridOpacity(atIndex index: Int) -> Double {
        if detail == nil { return 1.0 }
        if detail == index { return 0.0 }
        return 1.0 - dragScale
    }
    
    private var detailGesture: some Gesture {
        let tap = TapGesture().onEnded { _ in
            detail = nil
        }
        let drag = DragGesture()
            .updating($offset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                if value.velocity.height > 0 {
                    detail = nil
                }
            }
        return drag.exclusively(before: tap)
    }
}

#Preview {
    NavigationStack {
        PhotoGrid()
    }
}
