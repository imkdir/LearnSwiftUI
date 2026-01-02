//
//  StickyHeader.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/2/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var stickyFrames: [Namespace.ID: CGRect]?
}

struct StickyFramePreference: PreferenceKey {
    typealias Value = [Namespace.ID: CGRect]
    static var defaultValue: Value = [:]
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

struct Sticky: ViewModifier {
    let namespace: String
    
    @Namespace private var id
    @State private var frame: CGRect = .zero
    @Environment(\.stickyFrames) private var frames
    
    var pushingFrame: CGRect? {
        guard let frames else {
            print("Warning: Using .sticky(namespace:) without .stickyHeaders()")
            return nil
        }
        return frames
            .filter({ $0.key != id })
            .values
            .first(where: {
                frame.minY < $0.minY && $0.minY < frame.height
            })
    }
    
    private var offsetY: CGFloat {
        guard frame.minY < 0 else { return 0 }
        var offsetY = -frame.minY
        if let pushingFrame {
            offsetY -= frame.height - pushingFrame.minY
        }
        return offsetY
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .zIndex(offsetY > 0 ? .infinity : 0)
            .background {
                Color.clear
                    .onGeometryChange(for: CGRect.self) {
                        $0.frame(in: .named(namespace))
                    } action: {
                        frame = $0
                    }
            }
            .preference(key: StickyFramePreference.self, value: [id: frame])
    }
    
}

extension View {
    func sticky(in namespace: String) -> some View {
        modifier(Sticky(namespace: namespace))
    }
}

struct StickyContainer: ViewModifier {
    @State private var frames: [Namespace.ID: CGRect] = [:]
    
    func body(content: Content) -> some View {
        content
            .environment(\.stickyFrames, frames)
            .onPreferenceChange(StickyFramePreference.self) {
                frames = $0
            }
    }
}

extension View {
    func stickyHeaders() -> some View {
        modifier(StickyContainer())
    }
}


struct StickyHeaderDemo: View {
    private let namespace = "demo"
    
    var body: some View {
        ScrollView {
            Image(systemName: "globe")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .padding()
            
            ForEach(0..<20) { idx in
                Text("Header \(idx)")
                    .fontWeight(.semibold)
                    .font(.title)
                    .padding(4)
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .sticky(in: namespace)
                Text(loremipsum)
                    .padding()
            }
        }
        .coordinateSpace(.named(namespace))
        .stickyHeaders()
    }
}

private let loremipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam mattis magna at urna porta, vitae dictum ex malesuada. Mauris magna velit, interdum at eros ac, bibendum blandit quam. Fusce gravida dolor eget porta maximus. Interdum et malesuada fames ac ante ipsum primis in faucibus. Nullam interdum tellus ac diam tristique, eget iaculis risus dictum. Maecenas at neque auctor, pellentesque est vel, aliquam diam. Duis tellus ex, cursus in pharetra non, elementum non nunc. Nullam eu dolor blandit, sodales tellus quis, egestas neque. Donec rutrum sed lorem ac vestibulum. Cras ultrices arcu ut vehicula rutrum. Aenean placerat purus a metus efficitur consequat."

#Preview {
    StickyHeaderDemo()
}
