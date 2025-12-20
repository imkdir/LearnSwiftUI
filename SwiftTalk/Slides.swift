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

struct Presentation<Theme: ViewModifier>: View {
    var slides: [AnyView]
    var theme: Theme
    
    @State private var currentSlide = 0
    @State private var currentStep = 0
    @State private var stepAnimations: [Animation] = []
    
    init(theme: Theme, @SlideBuilder slides: () -> [AnyView]) {
        self.theme = theme
        self.slides = slides()
    }
    
    private func nextSlide() {
        if currentStep < stepAnimations.count {
            withAnimation(stepAnimations[currentStep]) {
                currentStep += 1
            }
        } else if currentSlide < slides.count - 1 {
            withAnimation(.smooth) {
                currentSlide += 1
            }
            currentStep = 0
            stepAnimations.removeAll()
        }
    }
    
    private func previousSlide() {
        if currentSlide > 0 {
            withAnimation(.smooth) {
                currentSlide -= 1
            }
            currentStep = 0
            stepAnimations.removeAll()
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SlideContainer(content: slides[currentSlide], theme: theme)
                .environment(\.currentStep, currentStep)
                .onPreferenceChange(SlideStepAnimationKey.self) {
                    self.stepAnimations = $0
                }
                .id(currentSlide)
                .transition(.offset(.zero))

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

struct SlideContainer<Theme: ViewModifier>: View {
    var size: CGSize = .init(width: 1920, height: 1080)
    var content: AnyView
    var theme: Theme
    
    private func scale(_ proxy: GeometryProxy) -> CGFloat {
        let ps = proxy.size
        return min(ps.width/size.width, ps.height/size.height)
    }
    
    var body: some View {
        GeometryReader { proxy in
            content
                .frame(width: size.width, height: size.height)
                .modifier(theme)
                .scaleEffect(scale(proxy))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

extension Presentation where Theme == EmptyModifier {
    init(@SlideBuilder slides: () -> [AnyView]) {
        self.theme = .identity
        self.slides = slides()
    }
}

extension EnvironmentValues {
    @Entry var currentStep: Int = 0
}

struct SlideStepAnimationKey: PreferenceKey {
    static var defaultValue: [Animation] = []
    
    static func reduce(value: inout [Animation], nextValue: () -> [Animation]) {
        value = nextValue()
    }
}

struct Slide<Content: View>: View {
    let stepAnimations: [Animation]
    let content: (Int) -> Content
    
    var numberOfSteps: Int {
        stepAnimations.count + 1
    }
    
    @Environment(\.currentStep) private var step
    
    var body: some View {
        content(step)
            .preference(key: SlideStepAnimationKey.self, value: stepAnimations)
    }
}

extension Slide {
    init(numberOfSteps: Int, content: @escaping (Int) -> Content) {
        self.stepAnimations = [Animation](repeating: .default, count: numberOfSteps-1)
        self.content = content
    }
}

struct ImageSlide: View {
    let imageName: String
    
    var body: some View {
        Slide(stepAnimations: [.bouncy]) { step in
            Image(systemName: imageName)
                .frame(maxWidth: .infinity, alignment: step == 0 ? .leading : .trailing)
                .padding(50)
        }
    }
}

struct AnyViewModifier: ViewModifier {
    let apply: (Content) -> AnyView
    
    init<V: View>(transform: @escaping (Content) -> V) {
        self.apply = { AnyView(transform($0)) }
    }
    
    func body(content: Content) -> AnyView {
        apply(content)
    }
}

extension EnvironmentValues {
    @Entry var headerStyle = AnyViewModifier(transform: { $0 })
}

struct Header<Content: View>: View {
    var content: Content
    
    @Environment(\.headerStyle) private var headerStyle
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content.modifier(headerStyle)
    }
}

extension View {
    func headerStyle<V: View>(_ transform: @escaping (AnyViewModifier.Content) -> V) -> some View {
        self.environment(\.headerStyle, AnyViewModifier(transform: transform))
    }
}

struct BlueSky: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .background(.blue)
            .font(.custom("Avenir", size: 40))
            .headerStyle {
                $0.padding(40).border(.white, width: 2)
            }
    }
}

struct Slides: View {
    @Namespace var slides
    
    var body: some View {
        Presentation(theme: BlueSky()) {
            Header {
                Text("Hello World!")
            }
            .matchedGeometryEffect(id: "header", in: slides)
            
            VStack(spacing: 120) {
                Header {
                    Text("Hello World!")
                }
                .matchedGeometryEffect(id: "header", in: slides)
                Text("A tortoise tutorial")
            }

            ImageSlide(imageName: "tortoise")
        }
    }
}
