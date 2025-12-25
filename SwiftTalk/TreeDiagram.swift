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

extension HorizontalAlignment {
    struct NodeCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    
    static let nodeCenter = Self(NodeCenter.self)
}

struct Diagram<A, Node: View>: View {
    let tree: Tree<A>
    @ViewBuilder let node: (Tree<A>) -> Node
    
    private let coordinate = "diagram"
    
    func generateGuideIDs(_ items: [Tree<A>]) -> Set<UUID> {
        let cIndex = items.count / 2
        let indexes = items.count.isMultiple(of: 2)
            ? [cIndex, cIndex-1]
            : [cIndex]
        return Set(indexes.map({ items[$0].id }))
    }
    
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
        VStack(alignment: .nodeCenter, spacing: 16) {
            node(tree)
                .measureFrame(id: tree.id, in: coordinate)
            if !tree.children.isEmpty {
                let guideIDs = generateGuideIDs(tree.children)
                HStack(alignment: .top, spacing: 10) {
                    ForEach(tree.children) {
                        let alignment = guideIDs.contains($0.id)
                            ? HorizontalAlignment.nodeCenter
                            : .center
                        Diagram(tree: $0, node: node)
                            .measureFrame(id: $0.id, in: coordinate)
                            .alignmentGuide(alignment) {
                                $0[HorizontalAlignment.center]
                            }
                    }
                }
            }
        }
        .backgroundPreferenceValue(DiagramNodeFramePreference.self, background)
        .coordinateSpace(.named(coordinate))
        .preference(key: DiagramNodeFramePreference.self, value: [:])
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

struct TreeDiagramCanvas: View {
    @State private var root = Tree("Root")
    
    var body: some View {
        Diagram(tree: root) { subtree in
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
    TreeDiagramCanvas()
}
