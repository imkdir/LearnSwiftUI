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
    var children: [Tree<A>]
    
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
    func measureFrame(id: UUID, in coordinate: NamedCoordinateSpace) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: DiagramNodeFramePreference.self, value: [
                    id: proxy.frame(in: coordinate)
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

struct Root {}
struct Next<Level> {}

extension HorizontalAlignment {
    struct NodeCenter<Level>: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    
    static func nodeCenter<Level>(_ level: Level.Type) -> HorizontalAlignment {
        HorizontalAlignment(NodeCenter<Level>.self)
    }
}

struct Diagram<L, A, Node: View>: View {
    let tree: Tree<A>
    @ViewBuilder let node: (Tree<A>) -> Node
    let isCenterGuide: Bool
    
    func generateGuideIDs(_ items: [Tree<A>]) -> Set<UUID> {
        let cIndex = items.count / 2
        let indexes = items.count.isMultiple(of: 2)
            ? [cIndex, cIndex-1]
            : [cIndex]
        return Set(indexes.map({ items[$0].id }))
    }
    
    var body: some View {
        VStack(alignment: .nodeCenter(Next<L>.self), spacing: 16) {
            node(tree)
                .measureFrame(id: tree.id, in: canvas)
                .alignmentGuide(isCenterGuide
                    ? .nodeCenter(L.self) : .center
                ) { $0[HorizontalAlignment.center] }
            if !tree.children.isEmpty {
                let guideIDs = generateGuideIDs(tree.children)
                HStack(alignment: .top, spacing: 10) {
                    ForEach(tree.children) {
                        Diagram<Next<L>, A, Node>(
                            tree: $0,
                            node: node,
                            isCenterGuide: guideIDs.contains($0.id)
                        )
                    }
                }
            }
        }
    }
}

struct Vertices<A>: View {
    let tree: Tree<A>
    let values: [UUID: CGRect]
    
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
    
    var body: some View {
        ZStack {
            let rootFrame = values[tree.id, default: .null]
            ForEach(tree.children) { child in
                let childFrame = values[child.id, default: .null]
                Line(from: rootFrame[.bottom], to: childFrame[.top])
                    .stroke(lineWidth: 1)
                Vertices(tree: child, values: values)
            }
        }
    }
}

extension Tree {
    mutating func insert(value: A, parent: UUID) {
        if parent == id {
            children.append(.init(value))
        } else {
            for i in children.indices {
                children[i].insert(value: value, parent: parent)
            }
        }
    }
    
}

private let canvas = NamedCoordinateSpace.named("canvas")

struct Canvas<A, Node: View>: View {
    var tree: Tree<A>
    @ViewBuilder var node: (Tree<A>) -> Node
    
    func background(_ values: [UUID: CGRect]) -> some View {
        Vertices(tree: tree, values: values)
    }
    
    var body: some View {
        Diagram<Root, A, Node>(tree: tree, node: node, isCenterGuide: false)
            .coordinateSpace(canvas)
            .backgroundPreferenceValue(DiagramNodeFramePreference.self, background)
    }
}

struct TreeDiagramDemo: View {
    @State private var root = Tree(
        "Root",
        children: [
            .init("First Child w/ a long face"),
            .init("Second Child")
        ]
    )
    
    var body: some View {
        Canvas(tree: root) { subtree in
            Text(subtree.value)
                .font(.footnote)
                .fixedSize()
                .foregroundStyle(.white)
                .padding(4)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .onTapGesture {
                    root.insert(value: "New Leaf", parent: subtree.id)
                }
        }
    }
}

#Preview {
    TreeDiagramDemo()
}
