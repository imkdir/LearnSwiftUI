//
//  StaggeredStack.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/1/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var colorfulDelays: [Namespace.ID: Double] = [:]
}

enum Colors: CaseIterable, Identifiable, View {
    case red, orange, yellow, green, blue, purple, brown, cyan, teal, indigo, mint, pink
    
    var id: Self { self }
    
    struct NamespacesPreference: PreferenceKey {
        static var defaultValue: [Namespace.ID] = []
        
        static func reduce(value: inout [Namespace.ID], nextValue: () -> [Namespace.ID]) {
            value += nextValue()
        }
    }
    
    struct StaggerParent: ViewModifier {
        @State private var viewIDs: [Namespace.ID] = []
        
        var delays: [Namespace.ID: Double] {
            Dictionary(uniqueKeysWithValues: viewIDs.enumerated().map({
                ($1, Double($0) * 0.2)
            }))
        }
        
        func body(content: Content) -> some View {
            content
                .environment(\.colorfulDelays, delays)
                .onPreferenceChange(NamespacesPreference.self) {
                    self.viewIDs = $0
                }
        }
    }
    
    struct StaggerChild: ViewModifier {
        @Namespace private var namespace
        @Environment(\.colorfulDelays) private var delays
        @State private var visible = false
        
        var delay: Double? {
            delays[namespace]
        }
        
        func body(content: Content) -> some View {
            content
                .opacity(visible ? 1.0 : 0.0)
                .preference(key: Colors.NamespacesPreference.self, value: [namespace])
                .onChange(of: delay) { _, newValue in
                    if let newValue {
                        withAnimation(.smooth.delay(newValue)) {
                            visible = true
                        }
                    }
                }
        }
    }


    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color.gradient)
            .frame(height: 80)
            .modifier(StaggerChild())
    }
    
    var color: Color {
        switch self {
        case .red: Color.red
        case .orange: Color.orange
        case .yellow: Color.yellow
        case .green: Color.green
        case .blue: Color.blue
        case .purple: Color.purple
        case .brown: Color.brown
        case .cyan: Color.cyan
        case .teal: Color.teal
        case .indigo: Color.indigo
        case .mint: Color.mint
        case .pink: Color.pink
        }
    }
}

struct StaggeredRevisited: View {
    
    var columns: [GridItem] {
        [.init(.adaptive(minimum: 80), spacing: 16)]
    }
    
    var body: some View {
        VStack {
            Colors.red
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Colors.allCases.dropFirst()) {
                    $0
                }
            }
        }
        .padding()
        .modifier(Colors.StaggerParent())
    }
}

#Preview {
    StaggeredRevisited()
}
