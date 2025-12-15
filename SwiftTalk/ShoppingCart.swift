import SwiftUI

enum ShoppingItem: String, CaseIterable, Identifiable {
    case airplane, studentdesk, hourglass, headphones, lightbulb
    
    var id: String {
        rawValue
    }
    
    var color: Color {
        switch self {
        case .airplane:     Color.blue
        case .studentdesk:  Color.orange
        case .hourglass:    Color.yellow
        case .headphones:   Color.cyan
        case .lightbulb:    Color.indigo
        }
    }
    
    static let size: CGFloat = 50
}

struct CartItem: Identifiable {
    let id = UUID()
    let item: ShoppingItem
    let anchor: Anchor<CGPoint>
}

struct AnchorKey<A>: PreferenceKey {
    typealias Value = Anchor<A>?
    static var defaultValue: Value { nil }
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue() ?? value
    }
}

extension View {
    func overlayWithAnchor<A, V: View>(value: Anchor<A>.Source, transform: @escaping (Anchor<A>) -> V) -> some View {
        anchorPreference(key: AnchorKey<A>.self, value: value, transform: { $0 })
            .overlayPreferenceValue(AnchorKey<A>.self) { anchor in
                transform(anchor!)
            }
    }
}

struct ShoppingItemView: View {
    let item: ShoppingItem
    
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(item.color)
            .frame(width: ShoppingItem.size, height: ShoppingItem.size)
            .overlay {
                Image(systemName: item.rawValue)
                    .foregroundStyle(.white)
            }
    }
}

struct ShoppingCart: View {
    @State private var cartItems: [CartItem] = []
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                ForEach(ShoppingItem.allCases) { item in
                    ShoppingItemView(item: item)
                        .overlayWithAnchor(value: .center) { anchor in
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    addToCart(item: item, anchor: anchor)
                                }
                        }
                }
            }
            .padding(20)
            
            Spacer()
                .overlay {
                    LoadingIndicator() 
                }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(cartItems) {
                        ShoppingItemView(item: $0.item)
                            .modifier(AppearFrom(anchor: $0.anchor, animation: .bouncy))
                            .frame(width: ShoppingItem.size, height: ShoppingItem.size)
                    }
                }
                .animation(.bouncy, value: cartItems.count)
                .padding(20)
            }
            .scrollClipDisabled()
        }
        .padding(.vertical)
    }
    
    private func addToCart(item: ShoppingItem, anchor: Anchor<CGPoint>) {
        let newItem = CartItem(item: item, anchor: anchor)
        cartItems.insert(newItem, at: 0)
    }
}

fileprivate struct AppearFrom: ViewModifier {
    let anchor: Anchor<CGPoint>
    let animation: Animation
    
    @State private var didAppear: Bool = false
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .offset(didAppear ? .zero : .init(point: proxy[anchor]))
                .onAppear {
                    withAnimation(animation) {
                        didAppear = true
                    }
                }
        }
    }
}

extension CGSize {
    fileprivate init(point: CGPoint) {
        self.init(width: point.x, height: point.y)
    }
}
