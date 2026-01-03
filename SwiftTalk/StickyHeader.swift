//
//  StickyHeader.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/2/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var stickyFrames: Sticky.IdentifiedFrames.Value?
}

struct Sticky {
    
    static let coordinateSpace: NamedCoordinateSpace = .named("Sticky")
    
    struct IdentifiedFrames: PreferenceKey {
        typealias Value = [Namespace.ID: CGRect]
        static var defaultValue: Value = [:]
        
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value.merge(nextValue()) { $1 }
        }
    }

    enum Role {
        case container, element
    }
    
    struct Element: ViewModifier {
        @Namespace private var id
        @State private var frame: CGRect = .zero
        @Environment(\.stickyFrames) private var frames
        
        private var pushingFrame: CGRect? {
            guard let frames else {
                print("Warning: Using .sticky() without .sticky(role: .container)")
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
                            $0.frame(in: Sticky.coordinateSpace)
                        } action: {
                            frame = $0
                        }
                }
                .preference(key: IdentifiedFrames.self, value: [id: frame])
        }
    }
    
    struct Container: ViewModifier {
        @State private var frames: [Namespace.ID: CGRect] = [:]
        
        func body(content: Content) -> some View {
            content
                .environment(\.stickyFrames, frames)
                .onPreferenceChange(IdentifiedFrames.self) {
                    frames = $0
                }
                .coordinateSpace(Sticky.coordinateSpace)
        }
    }
}


extension View {
    func sticky(role: Sticky.Role = .element) -> some View {
        Group {
            switch role {
            case .container:
                modifier(Sticky.Container())
            case .element:
                modifier(Sticky.Element())
            }
        }
    }
}

extension View {
    func measureFrame<T: Equatable>(_ keyPath: KeyPath<CGRect, T>, in coordinateSpace: NamedCoordinateSpace, perform: @escaping (T) -> Void) -> some View {
        background {
            Color.clear
                .onGeometryChange(
                    for: T.self,
                    of: { $0.frame(in: coordinateSpace)[keyPath: keyPath] },
                    action: perform
                )
        }
    }
}

struct StickyTabScrollView<Tab: Hashable & Comparable & View, Header: View, Picker: View, Content: View>: View {
    let currentTab: Tab
    @ViewBuilder var header: Header
    @ViewBuilder var picker: Picker
    @ViewBuilder var content: Content
    
    @State private var scrollOffset: [Tab: CGFloat] = [:]
    @State private var scrollTargetOffset: CGFloat = 0
    @State private var pickerFrameMinY: [String: CGFloat] = [:]
    
    struct Constants {
        static var scrollTarget: String { #function }
        static var outsideScrollView: String { #function }
        static var inScrollView: String { #function }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    header
                    
                    picker
                        .measureFrame(\.minY, in: .named(Constants.outsideScrollView)) {
                            pickerFrameMinY[Constants.outsideScrollView] = $0
                        }
                        .sticky() // ↑ sticky area, ↓ non-sticky area
                        .measureFrame(\.minY, in: .named(Constants.inScrollView)) {
                            pickerFrameMinY[Constants.inScrollView] = $0
                        }
                    
                    content
                }
                .measureFrame(\.minY, in: .named(Constants.outsideScrollView)) {
                    scrollOffset[currentTab] = $0
                }
                .coordinateSpace(.named(Constants.inScrollView))
                .overlay(alignment: .top) {
                    Color.clear
                        .frame(height: 0)
                        .id(Constants.scrollTarget)
                        .offset(y: scrollTargetOffset)
                }
            }
            .onChange(of: currentTab) { oldValue, _ in
                restoreScrollPosition(proxy, previousTab: oldValue)
            }
        }
        .sticky(role: .container)
        .coordinateSpace(.named(Constants.outsideScrollView))
        .overlay(alignment: .bottom) {
            debugger
        }
    }
    
    private func restoreScrollPosition(_ proxy: ScrollViewProxy, previousTab: Tab) {
        if pickerFrameMinY[Constants.outsideScrollView, default: 0] <= 0 {
            scrollTargetOffset = max(
                scrollOffset[currentTab].map({ -$0 }) ?? 0,
                pickerFrameMinY[Constants.inScrollView, default: 0]
            )
            proxy.scrollTo(Constants.scrollTarget, anchor: .top)
        } else {
            scrollOffset[currentTab] = scrollOffset[previousTab, default: 0]
        }
    }
    
    struct DebugInfo<Key: Hashable & Comparable, Value, RowContent: View>: View {
        let name: String
        let info: [Key: Value]
        @ViewBuilder let rowContent: (Key, Value) -> RowContent
        
        var body: some View {
            VStack {
                Text(name)
                ForEach(
                    info.sorted(by: { $0.key < $1.key }),
                    id: \.0,
                    content: rowContent
                )
            }
            .padding()
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.6))
            }
        }
    }
    
    @ViewBuilder
    var debugger: some View {
        VStack {
            DebugInfo(
                name: "picker.frame.minY",
                info: pickerFrameMinY
            ) { key, value in
                HStack {
                    Text(key)
                    Spacer()
                    Text(String(format: "%.2f", value))
                }
            }
            DebugInfo(
                name: "scrollView.contentOffset.y",
                info: scrollOffset
            ) { key, value in
                HStack {
                    key
                    Spacer()
                    Text(String(format: "%.2f", value))
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.8))
        }
        .padding()
    }
    
}

private let figureItems = (0...60).map { _ in StaggerItem() }
private let natureItems = (0...60).map { _ in StaggerItem(nature: true) }

enum StickyTab: String, CaseIterable, Identifiable {
    case figure, leaf
    
    var id: Self { self }
}

extension StickyTab: View {
    var body: some View {
        Image(systemName: rawValue)
    }
}

extension StickyTab: Comparable {
    static func < (lhs: StickyTab, rhs: StickyTab) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct StickyHeaderDemo: View {
    @State private var selectedTab: StickyTab = .figure
    
    var body: some View {
        StickyTabScrollView(currentTab: selectedTab) {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.tint)
                
                Text("Hello, world!")
            }
        } picker: {
            Picker("Tab", selection: $selectedTab) {
                ForEach(StickyTab.allCases) {
                    $0
                }
            }
            .pickerStyle(.segmented)
            .padding()

        } content: {
            let columns: [GridItem] = [.init(.adaptive(minimum: 80), spacing: 16)]
            let items: [StaggerItem] = switch selectedTab {
            case .figure: figureItems
            case .leaf: natureItems
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { $0 }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    StickyHeaderDemo()
}
