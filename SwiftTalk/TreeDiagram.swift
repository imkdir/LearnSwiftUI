//
//  TreeNode.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/25/25.
//

import SwiftUI

struct Tree<A>: Identifiable {
    let id = UUID()
    let value: A
    let children: [Tree<A>]
    
    init(_ value: A, children: [Tree<A>] = []) {
        self.value = value
        self.children = children
    }
}

struct DiagramNodeFramePreference: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    
    static func reduce(value: inout [UUID : CGRect], nextValue: () -> [UUID : CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func measureFrame(id: UUID, in coordinate: String) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: DiagramNodeFramePreference.self, value: [
                    id: proxy.frame(in: .named(coordinate))
                ])
            }
        }
    }
}

extension CGRect {
    subscript(point: UnitPoint) -> CGPoint {
        .init(x: minX + point.x * width, y: minY + point.y * height)
    }
}

struct Diagram<A, Node: View>: View {
    let tree: Tree<A>
    @ViewBuilder let node: (A) -> Node
    
    private let coordinate = "diagram"
    
    struct Line: Shape {
        let from: CGPoint
        let to: CGPoint
        
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: from)
                p.addLine(to: to)
            }
        }
    }
    
    func background(_ value: [UUID: CGRect]) -> some View {
        Group {
            if let rootFrame = value[tree.id] {
                let childFrames: [(UUID, CGRect)] = value.filter({ $0.key != tree.id })
                ZStack {
                    ForEach(childFrames, id: \.0) { (_, childFrame) in
                        Line(from: rootFrame[.bottom], to: childFrame[.top])
                            .stroke(lineWidth: 1)
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            node(tree.value)
                .measureFrame(id: tree.id, in: coordinate)
            HStack(spacing: 10) {
                ForEach(tree.children) {
                    Diagram(tree: $0, node: node)
                        .measureFrame(id: $0.id, in: coordinate)
                }
            }
        }
        .backgroundPreferenceValue(DiagramNodeFramePreference.self, background)
        .coordinateSpace(.named(coordinate))
        .preference(key: DiagramNodeFramePreference.self, value: [:])
    }
}

struct TreeDiagramCanvas: View {
    let sample = Tree("Root", children: [
        .init("Child A w/ a long face"),
        .init("Child B")
    ])
    var body: some View {
        Diagram(tree: sample) { value in
            Text(value)
                .font(.footnote)
                .fixedSize()
                .foregroundStyle(.white)
                .padding(4)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
}

#Preview {
    TreeDiagramCanvas()
}
