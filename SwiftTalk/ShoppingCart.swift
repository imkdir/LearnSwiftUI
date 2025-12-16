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
    let anchor: Anchor<CGPoint>?
}

struct AnchorKey<A>: PreferenceKey {
    typealias Value = Anchor<A>?
    static var defaultValue: Value { nil }
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue() ?? value
    }
}

extension View {
    func overlayWithAnchor<A, V: View>(value: Anchor<A>.Source, transform: @escaping (Anchor<A>?) -> V) -> some View {
        anchorPreference(key: AnchorKey<A>.self, value: value, transform: { $0 })
            .overlayPreferenceValue(AnchorKey<A>.self) { anchor in
                transform(anchor)
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
    
    @State private var dropZoneFrame: CGRect = .zero
    @State private var isHoveringOverCart = false
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                ForEach(ShoppingItem.allCases) { item in
                    ShoppingItemView(item: item)
                        .modifier(Draggable(
                            coordinateSpace: "PageSpace",
                            dropZoneFrame: dropZoneFrame,
                            onDragChanged: { hovering in
                                withAnimation {
                                    isHoveringOverCart = hovering
                                }
                            }, onEnded: { anchor, _ in
                                withAnimation {
                                    addToCart(item: item, anchor: anchor)
                                }
                            }
                        ))
                }
            }
            .padding(20)
            .zIndex(2)
            
            Spacer()
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(cartItems) {
                        ShoppingItemView(item: $0.item)
                            .modifier(AppearFrom(anchor: $0.anchor, animation: .bouncy))
                            .frame(width: ShoppingItem.size, height: ShoppingItem.size)
                            .transition(.identity)
                    }
                }
                .animation(.bouncy, value: cartItems.count)
                .frame(height: ShoppingItem.size)
            }
            .scrollClipDisabled()
            .zIndex(1)
            .padding(20)
            .background(isHoveringOverCart ? Color(uiColor: .secondarySystemBackground) : nil)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("PageSpace"))
            } action: { newValue in
                dropZoneFrame = newValue
            }
        }
        .padding(.vertical)
        .coordinateSpace(name: "PageSpace")
    }
    
    private func addToCart(item: ShoppingItem, anchor: Anchor<CGPoint>?) {
        let newItem = CartItem(item: item, anchor: anchor)
        cartItems.insert(newItem, at: 0)
    }
}

fileprivate struct AppearFrom: ViewModifier {
    let anchor: Anchor<CGPoint>?
    let animation: Animation
    
    @State private var didAppear: Bool = false
    
    func body(content: Content) -> some View {
        if let anchor {
            GeometryReader { proxy in
                content
                    .offset(didAppear ? .zero : .init(point: proxy[anchor]))
                    .onAppear {
                        withAnimation(animation) {
                            didAppear = true
                        }
                    }
            }
        } else {
            content
        }
    }
}

fileprivate struct Draggable: ViewModifier {
    let coordinateSpace: String
    let dropZoneFrame: CGRect
    
    var onDragChanged: (Bool) -> Void
    var onEnded: (Anchor<CGPoint>?, Bool) -> Void
    
    @GestureState private var translation: CGSize = .zero
    @State private var isHovering = false
    
    var anchorValue: Anchor<CGPoint>.Source {
        .point(.init(x: translation.width, y: translation.height))
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(translation == .zero ? 1.0 : 0.8)
                .overlayWithAnchor(value: anchorValue) { anchor in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEnded(anchor, false)
                        }
                        .highPriorityGesture(
                            DragGesture(
                                minimumDistance: 1,
                                coordinateSpace: .named(coordinateSpace)
                            )
                            .updating($translation) { value, state, _ in
                                    state = value.translation
                            }
                            .onChanged({ value in
                                let isOver = dropZoneFrame.contains(value.location)
                                if isOver != isHovering {
                                    isHovering = isOver
                                    onDragChanged(isOver)
                                }
                            })
                            .onEnded({ value in
                                if dropZoneFrame.contains(value.location) {
                                    onEnded(anchor, true)
                                }
                                isHovering = false
                                onDragChanged(false)
                            })
                        )
                }
            if translation != .zero {
                content
                    .offset(translation)
                    .zIndex(1)
                    .transition(.offset(isHovering ? .zero : -translation))
            }
        }
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: translation)
        
    }
}

extension CGSize {
    fileprivate init(point: CGPoint) {
        self.init(width: point.x, height: point.y)
    }
}

prefix func -(size: CGSize) -> CGSize {
    CGSize(width: -size.width, height: -size.height)
}
