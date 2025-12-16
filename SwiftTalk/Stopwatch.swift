//
//  Stopwatch.swift
//  SwiftTalk
//
//  Created by 程東 on 12/16/25.
//

import SwiftUI

struct Stopwatch: View {
    @State private var maxLabelSize: CGFloat = 0
    
    var body: some View {
        HStack {
            Button {
                
            } label: {
                Text("Stop Now")
                    .modifier(SyncSize(maxSize: $maxLabelSize))
            }
            .foregroundStyle(.red)
            Spacer()
            
            Button {
                
            } label: {
                Text("Start")
                    .modifier(SyncSize(maxSize: $maxLabelSize))
            }
            .foregroundStyle(.green)
        }
        .buttonStyle(CircleStyle())
        .padding()
    }
}

struct CircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(20)
            .background {
                ZStack {
                    Circle()
                        .fill()
                    if configuration.isPressed {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                    }
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .padding(4)
                }
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

struct SyncSize: ViewModifier {
    @Binding var maxSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                max(proxy.size.width, proxy.size.height)
            } action: { newValue in
                if newValue > maxSize {
                    maxSize = newValue
                }
            }
            .frame(
                minWidth: maxSize > 0 ? maxSize : nil,
                minHeight: maxSize > 0 ? maxSize : nil
            )
    }
}

#Preview {
    Stopwatch()
}
