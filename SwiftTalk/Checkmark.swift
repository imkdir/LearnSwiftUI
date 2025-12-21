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
            p.move(to: .init(x: rect.minX, y: rect.midY))
            p.addLine(to: .init(x: rect.minX + rect.width/3, y: rect.maxY))
            p.addLine(to: .init(x: rect.maxX, y: rect.minY))
        }
    }
}

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
                    .stroke(lineWidth: 2)
                    .foregroundStyle(.white)
                    .padding(5)
            }
            .scaleEffect(scaleProgress)
            .offset(x: 8, y: -8)
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
                    .stroke(lineWidth: 2)
                    .animation(.linear(duration: duration/2).delay(duration/2), value: enabled)
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
                            .animation(.linear(duration: duration), value: enabled)
                    } else {
                        CheckmarkV2(enabled: enabled, duration: duration)
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
                    Image(systemName: "tortoise")
                },
                maximumValueLabel: {
                    Image(systemName: "hare")
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
