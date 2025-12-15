import SwiftUI

// 1. Data Model
struct ProductData {
    static let colors = [Color.red, Color.orange, Color.yellow, Color.green, Color.blue]
    static let icons = ["airplane", "studentdesk", "hourglass", "headphones", "lightbulb"]
}

// 2. A specific struct for the items flying into the cart
// Using Identifiable ensures SwiftUI tracks the transition correctly for each unique click.
struct FlyingItem: Identifiable {
    let id = UUID()
    let index: Int
    let anchor: Anchor<CGPoint>
}

// 3. Consolidated PreferenceKey
struct ItemAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGPoint>? { nil }
    
    static func reduce(value: inout Anchor<CGPoint>?, nextValue: () -> Anchor<CGPoint>?) {
        // We only care about the specific item being tapped,
        // so standard reduction isn't strictly necessary here,
        // but taking the last non-nil value is safe.
        value = nextValue() ?? value
    }
}

struct ShoppingItemView: View {
    let index: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(ProductData.colors[index % ProductData.colors.count])
            .frame(width: 50, height: 50)
            .overlay {
                Image(systemName: ProductData.icons[index % ProductData.icons.count])
                    .foregroundStyle(.white)
            }
    }
}

struct ShoppingCart: View {
    // We keep track of items "in flight" separate from the total count
    // to prevent the view hierarchy from growing infinitely.
    @State private var flyingItems: [FlyingItem] = []
    @State private var cartCount: Int = 0
    
    var body: some View {
        VStack {
            // Product Row
            HStack(spacing: 20) {
                ForEach(0..<5) { index in
                    ShoppingItemView(index: index)
                        // Capture the anchor for this specific item
                        .anchorPreference(key: ItemAnchorKey.self, value: .center) { $0 }
                        // Read the anchor immediately to allow interaction
                        .overlayPreferenceValue(ItemAnchorKey.self) { anchor in
                            GeometryReader { proxy in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let anchor = anchor {
                                            addToCart(index: index, anchor: anchor)
                                        }
                                    }
                            }
                        }
                }
            }
            
            Spacer()
                .frame(height: 140)
            
            // Cart Area
            CartIconView(count: cartCount)
                .background(
                    // We use the background to establish the coordinate space for the flight
                    GeometryReader { proxy in
                        ZStack {
                            ForEach(flyingItems) { item in
                                ShoppingItemView(index: item.index)
                                    // The animation happens on insertion
                                    .transition(
                                        .asymmetric(
                                            insertion: .offset(
                                                x: -getOffset(for: item.anchor, in: proxy).x,
                                                y: -getOffset(for: item.anchor, in: proxy).y
                                            ).combined(with: .opacity),
                                            removal: .identity
                                        )
                                    )
                            }
                        }
                        // Center the flying items on the cart
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                )
        }
    }
    
    // Helper to calculate distance from the item to the cart
    private func getOffset(for anchor: Anchor<CGPoint>, in proxy: GeometryProxy) -> CGPoint {
        let sourcePoint = proxy[anchor]
        let centerPoint = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
        return CGPoint(x: centerPoint.x - sourcePoint.x, y: centerPoint.y - sourcePoint.y)
    }
    
    private func addToCart(index: Int, anchor: Anchor<CGPoint>) {
        let newItem = FlyingItem(index: index, anchor: anchor)
        
        withAnimation(.bouncy(duration: 0.6)) {
            flyingItems.append(newItem)
        }
        
        // Logic to "Land" the item:
        // After the animation duration, remove the flying view and increment the counter.
        // This prevents the ZStack from holding thousands of views if the user clicks a lot.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Remove the specific item using ID to be safe
            if let _ = flyingItems.firstIndex(where: { $0.id == newItem.id }) {
                _ = flyingItems.removeFirst() // Simple FIFO removal for visual cleanup
                withAnimation {
                    cartCount += 1
                }
            }
        }
    }
}

// Extracted Subview for the Cart Icon
struct CartIconView: View {
    let count: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(.regularMaterial)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            .frame(width: 80, height: 80)
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.red))
                        .offset(x: 10, y: -10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay {
                Image(systemName: "cart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}
