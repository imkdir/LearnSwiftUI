//
//  Checkmark.swift
//  SwiftTalk
//
//  Created by 程東 on 12/21/25.
//

import SwiftUI

struct Checkmark: Shape {
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: .init(x: rect.minX, y: rect.midY + rect.height/5))
            p.addLine(to: .init(x: rect.minX + rect.width/3, y: rect.maxY))
            p.addLine(to: .init(x: rect.maxX, y: rect.minY))
        }
    }
}

let strokeStyle = StrokeStyle(
    lineWidth: 2,
    lineCap: .round,
    lineJoin: .round
)

struct CheckmarkV1: View, Animatable {
    
    init(enabled: Bool) {
        self.animatableData = enabled ? 1 : 0
    }
    
    var animatableData: CGFloat
    
    var scaleProgress: CGFloat {
        min(1, animatableData / 0.5)
    }
    
    var shapeProgress: CGFloat {
        max(0, (animatableData - 0.4) / 0.6)
    }
    
    var body: some View {
        Circle()
            .fill(.green)
            .frame(width: 16, height: 16)
            .overlay {
                Checkmark()
                    .trim(from: 0, to: shapeProgress)
                    .stroke(style: strokeStyle)
                    .foregroundStyle(.white)
                    .padding(5)
            }
            .scaleEffect(scaleProgress)
    }
}

struct CheckmarkV2: View {
    var enabled: Bool
    var duration: TimeInterval
    
    var body: some View {
        Circle()
            .fill(.green)
            .frame(width: 16, height: 16)
            .overlay {
                Checkmark()
                    .trim(from: 0, to: enabled ? 1 : 0)
                    .stroke(style: strokeStyle)
                    .animation(
                        .linear(duration: duration/2).delay(duration/2),
                        value: enabled
                    )
                    .foregroundStyle(.white)
                    .padding(5)
            }
            .scaleEffect(enabled ? 1 : 0)
            .animation(.linear(duration: duration/2), value: enabled)
    }
}

struct CheckmarkPreviews: View {
    @State private var enabled: Bool = false
    @State private var selectedVersion = "V1"
    @State private var duration: TimeInterval = 0.5
    
    private let versions = ["V1", "V2"]
    
    var body: some View {
        VStack(spacing: 50) {
            Image(systemName: "camera")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .padding(.bottom, 20)
                .overlay(alignment: .topTrailing) {
                    if selectedVersion == "V1" {
                        CheckmarkV1(enabled: enabled)
                            .animation(
                                .linear(duration: duration),
                                value: enabled
                            )
                            .offset(x: 4, y: -4)
                    } else {
                        CheckmarkV2(
                            enabled: enabled,
                            duration: duration
                        )
                        .offset(x: 4, y: -4)
                    }
                }
                .scaleEffect(2)
                .onTapGesture {
                    enabled.toggle()
                }
            
            Picker("", selection: $selectedVersion) {
                ForEach(versions, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
            
            Slider(
                value: $duration,
                in: 0.2...2.0,
                label: { Text("Duration") },
                minimumValueLabel: {
                    Image(systemName: "hare")
                },
                maximumValueLabel: {
                    Image(systemName: "tortoise")
                }
            )
        }
        .padding(.horizontal, 80)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    CheckmarkPreviews()
}
