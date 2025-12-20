//
//  Slides.swift
//  SwiftTalk
//
//  Created by 程東 on 12/20/25.
//

import SwiftUI

struct SlidesContainer<Content: View, Theme: ViewModifier>: View {
    var slides: [Content]
    var theme: Theme
    
    @State private var currentSlide = 0
    @State private var currentStep = 0
    @State private var numberOfSteps = 1
    
    private func nextSlide() {
        if currentStep < numberOfSteps - 1 {
            withAnimation(.bouncy) {
                currentStep += 1
            }
        } else if currentSlide < slides.count - 1 {
            currentSlide += 1
            currentStep = 0
        }
    }
    
    private func previousSlide() {
        if currentSlide > 0 {
            currentSlide -= 1
            currentStep = 0
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            slides[currentSlide]
                .environment(\.currentStep, currentStep)
                .onPreferenceChange(SlideStepsCountKey.self) {
                    self.numberOfSteps = $0
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(theme)
                .aspectRatio(16/9, contentMode: .fit)
                .border(Color.secondary)
            
            HStack {
                Button(action: previousSlide) {
                    Image(systemName: "arrow.backward")
                }
                Spacer()
                Text("\(currentSlide+1)/\(slides.count)")
                Spacer()
                Button(action: nextSlide) {
                    Image(systemName: "arrow.forward")
                }
            }
            .buttonStyle(.glass)
            .padding(20)
        }
    }
}

extension SlidesContainer where Theme == EmptyModifier {
    init(slides: [Content]) {
        self.init(slides: slides, theme: .identity)
    }
}

struct BlueSky: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .background(.blue)
            .font(.custom("Avenir", size: 40))
    }
}

extension EnvironmentValues {
    @Entry var currentStep: Int = 0
}

struct SlideStepsCountKey: PreferenceKey {
    static var defaultValue: Int = 1
    
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

struct Slide<Content: View>: View {
    let numberOfSteps: Int
    let content: (Int) -> Content
    
    @Environment(\.currentStep) private var step
    
    var body: some View {
        content(step)
            .preference(key: SlideStepsCountKey.self, value: numberOfSteps)
    }
}

struct ImageSlide: View {
    let imageName: String
    
    var body: some View {
        Slide(numberOfSteps: 2) { step in
            Image(systemName: imageName)
                .frame(maxWidth: .infinity, alignment: step == 0 ? .leading : .trailing)
                .padding(50)
        }
    }
}

struct Slides: View {
    
    var body: some View {
        SlidesContainer(slides: [
            AnyView(Text("Hello World!")),
            AnyView(ImageSlide(imageName: "tortoise"))
        ], theme: BlueSky())
    }
}
