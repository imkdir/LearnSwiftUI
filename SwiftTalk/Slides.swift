//
//  Slides.swift
//  SwiftTalk
//
//  Created by 程東 on 12/20/25.
//

import SwiftUI

@resultBuilder
struct SlideBuilder {
    static func buildExpression<Content: View>(_ expression: Content) -> AnyView {
        AnyView(expression)
    }
    
    static func buildBlock(_ components: AnyView...) -> [AnyView] {
        components
    }
}

struct SlidesContainer<Theme: ViewModifier>: View {
    var slides: [AnyView]
    var theme: Theme
    
    @State private var currentSlide = 0
    @State private var currentStep = 0
    @State private var numberOfSteps = 1
    
    init(theme: Theme, @SlideBuilder slides: () -> [AnyView]) {
        self.theme = theme
        self.slides = slides()
    }
    
    private func nextSlide() {
        if currentStep < numberOfSteps - 1 {
            withAnimation(.bouncy) {
                currentStep += 1
            }
        } else if currentSlide < slides.count - 1 {
            currentSlide += 1
            currentStep = 0
            numberOfSteps = 1
        }
    }
    
    private func previousSlide() {
        if currentSlide > 0 {
            currentSlide -= 1
            currentStep = 0
            numberOfSteps = 1
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
    init(@SlideBuilder slides: () -> [AnyView]) {
        self.theme = .identity
        self.slides = slides()
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
        SlidesContainer(theme: BlueSky()) {
            Text("Hello World!")
            ImageSlide(imageName: "tortoise")
        }
    }
}
