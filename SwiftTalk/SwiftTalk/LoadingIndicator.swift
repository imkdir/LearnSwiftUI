//
//  LoadingIndicator.swift
//  SwiftTalk
//
//  Created by 程東 on 12/13/25.
//

import SwiftUI

struct ArrowHead: Shape {
    
    var strokeStyle: StrokeStyle = .init()
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: .init(x: rect.minX, y: rect.maxY))
            p.addLine(to: .init(x: rect.midX, y: rect.minY))
            p.addLine(to: .init(x: rect.maxX, y: rect.maxY))
        }.strokedPath(strokeStyle)
    }
}

struct LoadingIndicator: View {
    
    let duration: Double = 1.6
    let strokeStyle: StrokeStyle = .init(lineWidth: 3, lineCap: .round, lineJoin: .round)
    
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ZStack {
            ArrowHead(strokeStyle: strokeStyle)
                .size(width: 30, height: 30)
                .offset(x: -15, y: -15)
                .modifier(TravlerEffect(guide: InfiniteShape(), progress: progress))
            Trail(content: InfiniteShape(), strokeStyle: strokeStyle, offset: progress)
        }
        .aspectRatio(16/9, contentMode: .fit)
        .frame(width: 240)
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) {
                self.progress = 1
            }
        }
    }
}
