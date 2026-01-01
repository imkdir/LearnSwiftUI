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
    
    init(data: [(CFTimeInterval, CGFloat)]) {
        guard let last = data.last,
              let first = data.first else {
            self.data = []
            return
        }
        let duration = last.0 - first.0
        guard duration > 0 else {
            self.data = []
            return
        }
        self.data = data.map({
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
    let buffer: CFTimeInterval = 3.0
    
    @State private var recording: [(CFTimeInterval, CGFloat)] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            PhaseAnimator([false, true]) {
                Circle()
                    .fill(Color.red)
                    .frame(height: 30)
                    .offset(x: $0 ? 200 : 0)
                    .modifier(RecorderEffect(animatableData: $0 ? 1 : 0) {
                        let now = CACurrentMediaTime()
                        let result = self.recording + [(now, $0)]
                        if let first = result.first, now - first.0 > buffer {
                            self.recording = Array(result
                                .drop(while: { now - $0.0 > buffer })
                            )
                        } else {
                            self.recording = result
                        }
                    })
            } animation: { _ in
                animation
            }
            AnimationCurve(data: recording)
                .stroke(Color.blue, lineWidth: 2)
                .padding()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .border(Color.secondary)
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
            Picker("Animation", selection: $animation) {
                ForEach(animations, id: \.self) {
                    Text(animationKeys[$0, default: "N/A"])
                        .fontWeight(.semibold)
                        .tag($0)
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #endif
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
