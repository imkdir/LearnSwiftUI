//
//  MatchedGeometryEffect.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/23/25.
//

import SwiftUI

struct MatchedGeometryEffectCoordinator: ViewModifier {
    typealias Database = [Key: Value]
    
    struct Key: Hashable {
        let id: AnyHashable
        let namespace: Namespace.ID
    }
    
    struct Value: Equatable {
        let frame: CGRect
        let anchor: UnitPoint
    }
    
    struct Preference: PreferenceKey {
        static var defaultValue: Database = [:]
        
        static func reduce(value: inout Database, nextValue: () -> Database) {
            value.merge(nextValue()) { $1 }
        }
    }

    @State private var database: Database = [:]
    
    func body(content: Content) -> some View {
        content
            .environment(\.matchedGeometryEffectDatabase, database)
            .onPreferenceChange(Preference.self) {
                database = $0
            }
    }
}

extension EnvironmentValues {
    @Entry var matchedGeometryEffectDatabase: MatchedGeometryEffectCoordinator.Database = [:]
}


extension CGRect {
    func point(at anchor: UnitPoint) -> CGPoint {
        .init(x: minX + anchor.x * width, y: minY + anchor.y * height)
    }
}

struct MatchedGeometryEffect<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID
    let properties: MatchedGeometryProperties
    let anchor: UnitPoint
    let isSource: Bool
    
    @Environment(\.matchedGeometryEffectDatabase) private var database
    @State private var originalFrame: CGRect = .zero
    
    private var key: MatchedGeometryEffectCoordinator.Key {
        .init(id: id, namespace: namespace)
    }
    
    private var sourceValue: MatchedGeometryEffectCoordinator.Value? {
        database[key]
    }
    
    private var sourceSize: CGSize? {
        if properties.contains(.size) {
            sourceValue?.frame.size
        } else {
            nil
        }
    }
    
    private var positionOffset: CGSize {
        guard let sourceValue, properties.contains(.position) else {
            return .zero
        }
        let sourcePoint = sourceValue.frame.point(at: sourceValue.anchor)
        let originalPoint = originalFrame.point(at: anchor)
        return .init(
            width: sourcePoint.x - originalPoint.x,
            height: sourcePoint.y - originalPoint.y
        )
    }
    
    func body(content: Content) -> some View {
        Group {
            if isSource {
                content
                    .background {
                        GeometryReader { proxy in
                            let frame = proxy.frame(in: .global)
                            
                            return Color.clear
                                .preference(
                                    key: MatchedGeometryEffectCoordinator.Preference.self,
                                    value: [self.key: .init(frame: frame, anchor: anchor)]
                                )
                        }
                    }
            } else {
                content
                    .onGeometryChange(for: CGPoint.self) {
                        $0.frame(in: .global).origin
                    } action: {
                        originalFrame.origin = $0
                    }
                    .hidden()
                    .overlay(alignment: .topLeading) {
                        content
                            .offset(positionOffset)
                            .onGeometryChange(for: CGSize.self) {
                                $0.frame(in: .global).size
                            } action: {
                                originalFrame.size = $0
                            }
                            .frame(
                                width: sourceSize?.width,
                                height: sourceSize?.height,
                                alignment: .topLeading
                            )
                    }
            }
        }
    }
}

extension View {
    func selectMatchedGeometryEffect<ID: Hashable>(useBuiltin: Bool, id: ID, in namespace: Namespace.ID, properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool = true) -> some View {
        Group {
            if useBuiltin {
                matchedGeometryEffect(
                    id: id,
                    in: namespace,
                    properties: properties,
                    anchor: anchor,
                    isSource: isSource
                )
            } else {
                modifier(
                    MatchedGeometryEffect(
                        id: id,
                        namespace: namespace,
                        properties: properties,
                        anchor: anchor,
                        isSource: isSource
                    )
                )
            }
        }
    }
}

struct MatchedGeometryEffectSample: View {
    let useBuiltin: Bool
    let properties: MatchedGeometryProperties
    let sourceAnchor: UnitPoint
    let targetAnchor: UnitPoint
    
    @Namespace var sample
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.red)
                .selectMatchedGeometryEffect(
                    useBuiltin: useBuiltin,
                    id: "42",
                    in: sample,
                    properties: properties,
                    anchor: sourceAnchor
                )
                .frame(width: 120, height: 120)
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.8))
                .selectMatchedGeometryEffect(
                    useBuiltin: useBuiltin,
                    id: "42",
                    in: sample,
                    properties: properties,
                    anchor: targetAnchor,
                    isSource: false
                )
                .frame(width: 80, height: 80)
                .border(.green)
            Circle()
                .fill(Color.blue.opacity(0.8))
                .selectMatchedGeometryEffect(
                    useBuiltin: useBuiltin,
                    id: "42",
                    in: sample,
                    properties: properties,
                    anchor: targetAnchor,
                    isSource: false
                )
                .frame(width: 40, height: 40)
                .border(.blue)
        }
    }
}

extension MatchedGeometryProperties: @retroactive Hashable {}

struct MatchedGeometryEffectDemo: View {
    @State private var properties: MatchedGeometryProperties = .frame
    @State private var sourceAnchor: UnitPoint = .center
    @State private var targetAnchor: UnitPoint = .center
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SwiftUI").font(.headline)
            MatchedGeometryEffectSample(useBuiltin: true, properties: properties, sourceAnchor: sourceAnchor, targetAnchor: targetAnchor)
            Text("SwiftTalk").font(.headline)
            MatchedGeometryEffectSample(useBuiltin: false, properties: properties, sourceAnchor: sourceAnchor, targetAnchor: targetAnchor)
            VStack {
                Text("Adjust controls to observe their behaviors.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Picker("Properties", selection: $properties) {
                    Text("Position").tag(MatchedGeometryProperties.position)
                    Text("Size").tag(MatchedGeometryProperties.size)
                    Text("Frame").tag(MatchedGeometryProperties.frame)
                }
                .pickerStyle(.segmented)
                
                HStack {
                    VStack {
                        Text("Source")
                            .font(.subheadline)
                        HStack {
                            Text("x")
                            Slider(value: $sourceAnchor.x, in: 0...1)
                        }
                        HStack {
                            Text("y")
                            Slider(value: $sourceAnchor.y, in: 0...1)
                        }
                    }
                    .padding()
                    #if os(iOS)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                    #endif
                    VStack {
                        Text("Target")
                            .font(.subheadline)
                        HStack {
                            Text("x")
                            Slider(value: $targetAnchor.x, in: 0...1)
                        }
                        HStack {
                            Text("y")
                            Slider(value: $targetAnchor.y, in: 0...1)
                        }
                    }
                    .padding()
                    #if os(iOS)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                    #endif
                }
                .padding(.vertical)
            }
            .padding(.horizontal, 40)
        }
        .modifier(MatchedGeometryEffectCoordinator())
        .padding()
    }
}

#Preview {
    MatchedGeometryEffectDemo()
}
