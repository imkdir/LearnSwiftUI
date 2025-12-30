//
//  PhotoGrid.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/29/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var transitionIsActive = false
}

struct TransitionReader<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content
    
    @Environment(\.transitionIsActive) private var active
    
    var body: some View {
        content(active)
    }
}

struct TransitionCoordinator: ViewModifier {
    var active: Bool
    
    func body(content: Content) -> some View {
        content
            .environment(\.transitionIsActive, active)
    }
}

struct GridCenterPreference: PreferenceKey {
    static var defaultValue: [Int: CGPoint] = [:]
    
    static func reduce(value: inout [Int : CGPoint], nextValue: () -> [Int : CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func measureGridCenter(_ idx: Int) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: GridCenterPreference.self,
                    value: [
                        idx: proxy.frame(in: .global).center
                    ]
                )
            }
        }
    }
}

struct PhotoGrid: View {
    @State private var slowAnimation: Bool = false
    @State private var detail: Int?
    
    @Namespace private var transition
    @Namespace private var idle
    
    @State private var gridCenterMap: [Int: CGPoint] = [:]
    @State private var detailCenter: CGPoint?
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)], spacing: 3) {
                    ForEach(1..<11) { idx in
                        let opacity = gridOpacity(atIndex: idx)
                        Image("beach_\(idx)")
                            .resizable()
                            .measureGridCenter(idx)
                            .matchedGeometryEffect(id: idx.description, in: transition)
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture {
                                    detail = idx
                            }
                            .opacity(opacity)
                            .animation(.default.speed(speed), value: opacity == 0)
                    }
                }
            }
            .onPreferenceChange(GridCenterPreference.self) {
                gridCenterMap = $0
            }
            if let detail {
                ZStack {
                    TransitionReader { active in
                        let namespace = active ? transition : idle
                        Image("beach_\(detail)")
                            .resizable()
                            .onGeometryChange(for: CGPoint.self, of: {
                                $0.frame(in: .global).center
                            }, action: {
                                detailCenter = $0
                            })
                            .matchedGeometryEffect(id: detail.description, in: namespace, isSource: false)
                            .aspectRatio(contentMode: .fit)
                            .offset(offset)
                            .scaleEffect(dragScale)
                            .gesture(detailGesture)
                    }
                }
                .zIndex(2)
                .id(detail)
                .transition(.modifier(active: TransitionCoordinator(active: true), identity: TransitionCoordinator(active: false)))
            }
        }
        .animation(.default.speed(speed), value: detail)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    slowAnimation.toggle()
                } label: {
                    Image(systemName: slowAnimation ? "tortoise": "hare")
                }
            }
        }
        .navigationTitle("Photos")
    }
    
    private var speed: Double {
        slowAnimation ? 0.2 : 1.0
    }
    
    @State private var offset: CGSize = .zero
    
    private var dragScale: Double {
        guard offset.height > 0 else { return 1.0 }
        return 1.0 - offset.height / 1000.0
    }
    
    private func gridOpacity(atIndex index: Int) -> Double {
        if detail == nil { return 1.0 }
        if detail == index { return 0.0 }
        return 1.0 - dragScale
    }
    
    private var detailGesture: some Gesture {
        let tap = TapGesture().onEnded { _ in
            detail = nil
        }
        let drag = DragGesture()
            .onChanged({ value in
                offset = value.translation
            })
            .onEnded { value in
                withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 100, initialVelocity: 0).speed(speed)) {
                    offset = .zero
                    if value.velocity.height > 0 {
                        detail = nil
                    }
                }
            }
        return drag.simultaneously(with: tap)
    }
}

#Preview {
    NavigationStack {
        PhotoGrid()
    }
}
