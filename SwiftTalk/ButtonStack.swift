//
//  ButtonStack.swift
//  SwiftTalk
//
//  Created by 程東 on 12/21/25.
//

import SwiftUI

struct ScalableButtonHideLabelPreferenceKey: PreferenceKey {
    static var defaultValue: Bool { false }
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension EnvironmentValues {
    @Entry var shouldScalableButtonLabelHidden = false
}

struct ScalableButton: View {
    let iconName: String
    let text: String
    
    @Environment(\.shouldScalableButtonLabelHidden) private var isLabelHidden
    
    var background: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isLabelHidden ? .red : .blue)
    }
    
    func content(_ hidesLabel: Bool = false) -> some View {
        HStack {
            Image(systemName: iconName)
            if !hidesLabel {
                Text(text)
                    .fixedSize()
            }
        }
        .foregroundStyle(.white)
        .padding()
    }
    
    var body: some View {
        content()
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let frame = proxy.frame(in: .named("Space"))
                    let size = proxy.size
                    let outOfBounds = frame.minX < 0
                    
                    content(isLabelHidden)
                        .frame(width: size.width, height: size.height)
                        .preference(key: ScalableButtonHideLabelPreferenceKey.self, value: outOfBounds)
                }
            }
            .frame(width: 0)
            .frame(maxWidth: .infinity)
            .background(background)
            .coordinateSpace(name: "Space")
    }
}

struct ScalablePlayground: View {
    @State private var spacing: CGFloat = 0
    @State private var shouldHideLabel = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer().frame(width: spacing)
                HStack {
                    ScalableButton(iconName: "play.fill", text: "Play")
                    ScalableButton(iconName: "pause.fill", text: "Pause")
                    ScalableButton(iconName: "stop.fill", text: "Stop")
                }
                .frame(maxWidth: .infinity)
                .environment(\.shouldScalableButtonLabelHidden, shouldHideLabel)
                .onPreferenceChange(ScalableButtonHideLabelPreferenceKey.self) {
                    shouldHideLabel = $0
                }
            }
            
            Slider(value: $spacing, in: 0...200)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ScalablePlayground()
}
