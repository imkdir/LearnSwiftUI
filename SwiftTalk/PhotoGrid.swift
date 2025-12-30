//
//  PhotoGrid.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/29/25.
//

import SwiftUI

protocol Vector {
    var first: CGFloat { get }
    var second: CGFloat { get }
    
    init(_ first: CGFloat, _ second: CGFloat)
}

extension CGPoint: Vector {
    var first: CGFloat { x }
    
    var second: CGFloat { y }
    
    init(_ first: CGFloat, _ second: CGFloat) {
        self.init(x: first, y: second)
    }
}

extension Vector {
    static func -(lhs: Self, rhs: Vector) -> Self {
        .init(lhs.first - rhs.first, lhs.second - rhs.second)
    }
    
    static func +(lhs: Self, rhs: Vector) -> Self {
        .init(lhs.first + rhs.first, lhs.second + rhs.second)
    }
    
    static func /(lhs: Self, rhs: CGFloat) -> Self {
        .init(lhs.first / rhs, lhs.second / rhs)
    }
    
    static func *(lhs: Self, rhs: CGFloat) -> Self {
        .init(lhs.first * rhs, lhs.second * rhs)
    }
    
    func dot(_ rhs: Vector) -> CGFloat {
        first * rhs.first + second * rhs.second
    }
    
    var length: CGFloat {
        sqrt(first * first + second * second)
    }
    
    var normalized: Self {
        let l = length
        return Self(first/l, second/l)
    }
    
    init<V: Vector>(_ other: V) {
        self.init(other.first, other.second)
    }
}

extension CGSize: Vector {
    var first: CGFloat { width }
    var second: CGFloat { height }
    init(_ first: CGFloat, _ second: CGFloat) {
        self.init(width: first, height: second)
    }
}


struct Ray: View {
    struct Line: Shape {
        let start: CGPoint
        let end: CGPoint
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: start)
                p.addLine(to: end)
            }
        }
    }
    
    struct Arrow: Shape {
        func path(in rect: CGRect) -> Path {
            return Path { p in
                p.addLines([
                    .init(x: rect.minX, y: rect.minY),
                    .init(x: rect.maxX, y: rect.midY),
                    .init(x: rect.minX, y: rect.maxY)
                ])
                p.closeSubpath()
            }
        }
    }
    
    let start: CGPoint
    let end: CGPoint
    var lineWidth: CGFloat = 2
    
    var angle: Angle {
        let dy = end.y - start.y
        let dx = end.x - start.x
        return Angle(radians: atan2(dy, dx))
    }
    

    var body: some View {
        ZStack(alignment: .topLeading) {
            Line(start: start, end: end)
                .stroke(lineWidth: lineWidth)
            
            Arrow()
                .fill()
                .frame(width: 10, height: 10)
                .rotationEffect(angle)
                .offset(x: end.x-5, y: end.y-5)
        }
    }
}

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
    @State private var detailCenter: CGPoint = .zero
    
    @State private var dragState: DragState?
    @State private var debugDragState: DragState?
    
    struct DragState: View {
        let origin: CGPoint
        var value: DragGesture.Value
        var target: CGPoint?
        
        var currentPosition: CGPoint {
            origin + value.translation
        }
        
        var directionToTarget: CGPoint? {
            target.map({ $0 - currentPosition })
        }
        
        var shouldClose: Bool {
            value.velocity.height > 0
        }
        
        var body: some View {
            ZStack {
                Ray(start: value.location, end: value.predictedEndLocation)
                    .foregroundStyle(Color.orange)
                directionToTarget.map({
                    Ray(start: value.location, end: value.location + $0)
                        .foregroundStyle(Color.blue)
                })
            }
        }
    }
    
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
                            .matchedGeometryEffect(id: detail.description, in: namespace, isSource: false)
                            .aspectRatio(contentMode: .fit)
                            .offset(offset)
                            .onGeometryChange(for: CGPoint.self, of: {
                                $0.frame(in: .global).center
                            }, action: {
                                detailCenter = $0
                            })
                            .scaleEffect(dragScale)
                            .gesture(detailGesture)
                    }
                }
                .zIndex(2)
                .id(detail)
                .transition(.modifier(active: TransitionCoordinator(active: true), identity: TransitionCoordinator(active: false)))
            }
        }
        .overlay {
            debugDragState
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
    
    private var offset: CGSize {
        dragState?.value.translation ?? .zero
    }
    
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
                if dragState == nil {
                    dragState = DragState(origin: detailCenter, value: value)
                } else {
                    dragState?.value = value
                }
            })
            .onEnded { value in
                guard var dragState, let detail else {
                    return
                }
                dragState.target = dragState.shouldClose
                    ? gridCenterMap[detail, default: .zero] : detailCenter
                
                debugDragState = dragState
                withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 100, initialVelocity: 0).speed(speed)) {
                    self.dragState = nil
                    if dragState.shouldClose {
                        self.detail = nil
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
