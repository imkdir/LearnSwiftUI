//
//  AnimationCurves.swift
//  SwiftTalk
//
//  Created by 程東 on 12/15/25.
//

import SwiftUI

struct RecorderEffect: GeometryEffect {
    var animatableData: CGFloat
    var callback: (CGFloat) -> Void
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        DispatchQueue.main.async {
            callback(animatableData)
        }
        return ProjectionTransform()
    }
}

struct AnimationCurve: Shape {
    let data: [CGPoint]
    
    init(data: [(CFTimeInterval, CGFloat)], sampleSize: CFTimeInterval = 3.0) {
        guard let last = data.last else {
            self.data = []
            return
        }
        let slice = data.drop(while: { $0.0 < last.0 - sampleSize })
        guard let first = slice.first else {
            self.data = []
            return
        }
        let duration = last.0 - first.0
        guard duration > 0 else {
            self.data = []
            return
        }
        self.data = slice.map({
            .init(x: CGFloat(($0.0 - first.0) / duration), y: $0.1)
        })
    }
    
    func path(in rect: CGRect) -> Path {
        guard !data.isEmpty else {
            return Path()
        }
        return Path { p in
            p.addLines(data)
        }.applying(.init(scaleX: rect.width, y: rect.height))
    }
}

struct AnimationCurveGraph: View {
    let animation: Animation
    
    @State private var recording: [(CFTimeInterval, CGFloat)] = []
    @State private var isRunning = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Circle()
                .fill(Color.red)
                .frame(height: 30)
                .offset(x: isRunning ? 120 : 0)
                .modifier(RecorderEffect(animatableData: isRunning ? 1 : 0) {
                    self.recording.append((CACurrentMediaTime(), $0))
                })
                .animation(animation.repeatForever(), value: isRunning)
            AnimationCurve(data: recording)
                .stroke(Color.blue, lineWidth: 2)
                .padding()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .border(Color.secondary)
        }.onAppear {
            isRunning = true
        }
    }
}

struct AnimationCurves: View {
    @State private var animation: Animation = .default
    
    let animations: [Animation] = [
        .default,
        .bouncy,
        .spring,
        .easeIn,
        .easeOut,
        .easeInOut,
        .snappy,
    ]
    
    var body: some View {
        VStack {
            AnimationCurveGraph(animation: animation)
                .id(animation) // FIX: animation locked in by "isRunning"
            Picker("Animation", selection: $animation) {
                ForEach(animations, id: \.self) {
                    Text(animationKeys[$0, default: "N/A"])
                        .fontWeight(.semibold)
                        .tag($0)
                }
            }
            .pickerStyle(.wheel)
        }.padding()
    }
}

private let animationKeys: [Animation: String] = [
    .default: "Default",
    .bouncy: "Bouncy",
    .spring: "Spring",
    .easeIn: "Ease In",
    .easeOut: "Ease Out",
    .easeInOut: "Ease In Out",
    .snappy: "Snappy",
]
