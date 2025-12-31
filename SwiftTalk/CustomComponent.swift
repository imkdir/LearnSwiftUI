//
//  CustomComponent.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/31/25.
//

import SwiftUI
import Foundation

struct CoffeeCartItem: Identifiable {
    let id: Int
    let name: String
    let price: Decimal
    var quantity: Int = 1
    
    var total: Decimal {
        price * Decimal(quantity)
    }
    
    static var sample: [CoffeeCartItem] {
       [
        .init(id: 1, name: "Ethiopia Hello Verity", price: 12.45),
        .init(id: 2, name: "Seasonal Blend, Spring Here", price: 9.99),
        .init(id: 3, name: "Indonesian Frinza Collective", price: 8.29),
        .init(id: 4, name: "House Blend Dark", price: 9.95)
       ]
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .bold()
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.blue)
            .overlay {
                configuration.isPressed
                    ? Color.black.opacity(0.2)
                    : Color.clear
            }
            .clipShape(Capsule())
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: Self { PrimaryActionButtonStyle() }
}

protocol StepperStyle {
    associatedtype Body: View
    typealias Configuration = StepperConfiguration
    
    func makeBody(_ configuration: Configuration) -> Body
}

struct StepperConfiguration {
    let value: Binding<Int>
    let range: ClosedRange<Int>
    let label: Label
    
    struct Label: View {
        let underlyingView: AnyView
        
        init(_ underlyingView: AnyView) {
            self.underlyingView = underlyingView
        }
        
        var body: some View {
            underlyingView
        }
    }
}

struct DefaultStepperStyle: StepperStyle {
    func makeBody(_ configuration: Configuration) -> some View {
        Stepper(value: configuration.value, in: configuration.range) {
            configuration.label
        }
    }
}

extension StepperStyle where Self == DefaultStepperStyle {
    static var `default`: Self { DefaultStepperStyle() }
}

struct CapsuleStepperStyle: StepperStyle {
    
    func makeBody(_ configuration: Configuration) -> some View {
        CapsuleStepper(configuration: configuration)
    }
}

struct CapsuleStepper: View {
    let configuration: StepperConfiguration
    
    @Environment(\.controlSize)
    private var controlSize
    
    var contentInset: EdgeInsets {
        switch controlSize {
        case .mini, .small:
            .init(horizontal: 4, vertical: 2)
        case .large, .extraLarge:
            .init(horizontal: 12, vertical: 6)
        default:
            .init(horizontal: 8, vertical: 4)
        }
    }
    
    func decrement() {
        configuration.value.wrappedValue -= 1
    }
    
    var decrementDisabled: Bool {
        value <= configuration.range.lowerBound
    }
    
    func increment() {
        configuration.value.wrappedValue += 1
    }
    
    var incrementDisabled: Bool {
        value >= configuration.range.upperBound
    }
    
    var value: Int {
        configuration.value.wrappedValue
    }
    
    var body: some View {
        HStack {
            configuration.label
            Spacer()
            HStack {
                Button(action: decrement) {
                    Image(systemName: "minus")
                        .accessibilityLabel("Decrement")
                }
                .disabled(decrementDisabled)
                
                Text(value.formatted())
                    .monospacedDigit()
                
                Button(action: increment) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Increment")
                }
                .disabled(incrementDisabled)
            }
            .buttonStyle(.plain)
            .padding(contentInset)
            .transformEnvironment(\.font) { font in
                guard font == nil else { return }
                switch controlSize {
                case .mini, .small:
                    font = .footnote
                case .large, .extraLarge:
                    font = .title
                default:
                    font = .body
                }
            }
            .background(Color(uiColor: .systemGray6))
            .clipShape(Capsule())
        }
    }
}

extension StepperStyle where Self == CapsuleStepperStyle {
    static var capsule: Self { CapsuleStepperStyle() }
}

struct MacintoshStepperStyle: StepperStyle {
    func makeBody(_ configuration: Configuration) -> some View {
        MacintoshStepper(configuration: configuration)
    }
}

struct OnHold: ViewModifier {
    let perform: () -> Void
    
    @State private var isPressed = false
    
    func action() async throws {
        perform()
        try await Task.sleep(for: .seconds(0.5))
        while true {
            perform()
            try await Task.sleep(for: .seconds(0.1))
        }
    }
    
    func body(content: Content) -> some View {
        content
            ._onButtonGesture(
                pressing: { isPressed = $0 },
                perform: perform
            )
            .task(id: isPressed) {
                guard isPressed else { return }
                do {
                    try await action()
                } catch {}
            }
    }
}

extension View {
    func onHold(perform: @escaping () -> Void) -> some View {
        modifier(OnHold(perform: perform))
    }
}

struct MacintoshStepper: View {
    let configuration: StepperConfiguration
    
    func decrement() {
        guard !decrementDisabled else {
            return
        }
        configuration.value.wrappedValue -= 1
    }
    
    var decrementDisabled: Bool {
        value <= configuration.range.lowerBound
    }
    
    func increment() {
        guard !incrementDisabled else {
            return
        }
        configuration.value.wrappedValue += 1
    }
    
    var incrementDisabled: Bool {
        value >= configuration.range.upperBound
    }
    
    var value: Int {
        configuration.value.wrappedValue
    }
    
    var body: some View {
        LabeledContent {
            HStack {
                ZStack {
                    Text(configuration.range.upperBound.formatted())
                        .hidden()
                    Text(configuration.value.wrappedValue.formatted())
                }
                .foregroundStyle(.primary)
                .monospacedDigit()
                VStack {
                    Image(systemName: "chevron.up")
                        .accessibilityLabel("Increment")
                        .font(.footnote)
                        .opacity(incrementDisabled ? 0.5 : 1.0)
                    Spacer()
                        .frame(height: 2)
                    Image(systemName: "chevron.down")
                        .accessibilityLabel("Decrement")
                        .font(.footnote)
                        .opacity(decrementDisabled ? 0.5 : 1.0)
                }
            }
            .padding(.init(horizontal: 8, vertical: 4))
            .background(Color(uiColor: .systemGray6))
            .overlay {
                VStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onHold(perform: increment)
                    Color.clear
                        .contentShape(Rectangle())
                        .onHold(perform: decrement)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } label: {
            configuration.label
        }

    }
}

extension StepperStyle where Self == MacintoshStepperStyle {
    static var macintosh: Self { MacintoshStepperStyle() }
}

extension EnvironmentValues {
    @Entry var stepperStyle: any StepperStyle = .default
}

extension View {
    func stepperStyle(_ style: some StepperStyle) -> some View {
        environment(\.stepperStyle, style)
    }
}

struct CartStepper<Label: View>: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    @ViewBuilder let label: Label
   
    @Environment(\.stepperStyle)
    private var style
    
    var body: some View {
        AnyView(
            style.makeBody(.init(
                value: $value,
                range: range,
                label: .init(AnyView(label)))
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityRepresentation(representation: {
            label
        })
        .accessibilityValue(value.formatted())
        .accessibilityAdjustableAction({ direction in
            switch direction {
            case .increment:
                value += 1
            case .decrement:
                value -= 1
            default:
                break
            }
        })
    }
}

struct CoffeeCart: View {
    private enum StepperOption: String, CaseIterable, Identifiable {
        case `default`
        case capsule
        case macintosh
        
        var id: Self { self }
        
        var name: String {
            rawValue.capitalized
        }
        
        var style: any StepperStyle {
            switch self {
            case .default:
                return .default
            case .capsule:
                return .capsule
            case .macintosh:
                return .macintosh
            }
        }
    }
    
    @State private var items = CoffeeCartItem.sample
    @State private var shipping: Decimal = 5.0
    @State private var selected: StepperOption = .default
    
    private var total: Decimal {
        items.map(\.total).reduce(0, +) + shipping
    }
    
    var checkout: some View {
        VStack {
            HStack {
                Text("Shipping:")
                Spacer()
                Text(shipping.formatted(.currency(code: "EUR")))
            }
            HStack {
                Text("Total:")
                Spacer()
                Text(total.formatted(.currency(code: "EUR")))
            }
            Button("Checkout") {
                print("Checkout!")
            }
            .buttonStyle(.primaryAction)

        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    var body: some View {
        List($items) { $item in
            HStack {
                Image(systemName: "bag")
                    .font(.title)
                VStack {
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text(item.price.formatted(.currency(code: "EUR")))
                    }
                    CartStepper(value: $item.quantity, range: 0...99) {
                        Text("Quantity:").font(.callout)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
        .environment(\.stepperStyle, selected.style)
        .safeAreaInset(edge: .bottom) {
            checkout
        }
        .navigationTitle("Cart")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Stepper Style", selection: $selected) {
                        ForEach(StepperOption.allCases) { option in
                            Text(option.name).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CoffeeCart()
    }
}
