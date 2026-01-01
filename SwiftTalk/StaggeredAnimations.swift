//
//  StaggeredAnimations.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/1/26.
//

import SwiftUI

struct MenuItemStyle: LabelStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
                .frame(width: 40, height: 40)
                .background {
                    Circle().fill(Color(uiColor: .systemGray6))
                }
                .alignmentGuide(.menu) { d in
                    d[HorizontalAlignment.center]
                }
        }
        .font(.footnote)
    }
}

extension LabelStyle where Self == MenuItemStyle {
    static var menuItem: Self { MenuItemStyle() }
}

extension HorizontalAlignment {
    static let menu = HorizontalAlignment(StaggeredMenu.Alignment.self)
}

extension View {
    func variadic<R: View>(_ transform: @escaping (_VariadicView.Children) -> R) -> some View {
        _VariadicView.Tree(Helper(transform: transform)) {
            self
        }
    }
}

private struct Helper<R: View>: _VariadicView.MultiViewRoot {
    let transform: (_VariadicView.Children) -> R
    
    func body(children: _VariadicView.Children) -> R {
        transform(children)
    }
}

struct StaggeredStack<Content: View>: View {
    let open: Bool
    var speed: Double = 0.1
    @ViewBuilder let content: Content
    
    var body: some View {
        content.variadic { children in
            ForEach(children.enumerated(), id: \.offset) { (offset, item) in
                let delay = open ? children.count - 1 - offset : offset
                item
                    .staggered(open: open, delay: Double(delay) * speed)
            }
        }
    }
}

extension View {
    func staggered(open: Bool, delay: TimeInterval) -> some View {
        modifier(Staggered(open: open, delay: delay))
    }
}

struct Staggered: ViewModifier {
    let open: Bool
    let delay: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            if open {
                content
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.bouncy.delay(delay), value: open)
    }
}

struct StaggeredMenu: View {
    enum Alignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    enum Item: Hashable, CaseIterable, Identifiable {
        case note, photo, video
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .note:
                "note.text"
            case .photo:
                "photo"
            case .video:
                "video"
            }
        }
        
        var text: String {
            switch self {
            case .note:
                "Take note"
            case .photo:
                "Take photo"
            case .video:
                "Record video"
            }
        }
    }
    
    @State private var open: Bool = true
    
    var body: some View {
        VStack(alignment: .menu) {
            StaggeredStack(open: open) {
                ForEach(Item.allCases) { item in
                    Label(item.text, systemImage: item.icon)
                        .labelStyle(.menuItem)
                }
            }
            Button {
                open.toggle()
            } label: {
                Image(systemName: "plus")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .background {
                        Circle()
                            .fill(Color(uiColor: .systemGray5))
                    }
            }
        }
    }
}

struct StaggeredAnimations: View {
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) {
            StaggeredMenu()
                .padding(24)
        }
    }
}

#Preview {
    StaggeredAnimations()
}
