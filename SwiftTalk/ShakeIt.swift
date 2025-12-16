//
//  ShakeIt.swift
//  SwiftTalk
//
//  Created by 程東 on 12/15/25.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    
    var offset: CGFloat
    
    init(shakes: Int) {
        self.offset = .init(shakes)
    }
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: 40 * sin(.init(offset) * 2.0 * .pi),
                y: 0
            )
        )
    }
}

struct ShakeIt: View {
    @State var shakes: Int = 1
    
    var body: some View {
        VStack(spacing: 60) {
            Circle()
                .fill(Color.red)
                .frame(width: 120, height: 120)
                .modifier(ShakeEffect(shakes: shakes))
                .animation(.bouncy, value: shakes)
                .onTapGesture {
                    shakes += 1
                }
        }
        .padding(20)
    }
}
