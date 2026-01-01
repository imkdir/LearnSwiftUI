//
//  LayoutInspector.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/31/25.
//

import SwiftUI
import Observation

extension EdgeInsets {
    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}

@Observable
final class Console {
    static let shared = Console()
    
    var logs: [Item] = []
    
    struct Item: Identifiable, View {
        let id = UUID()
        let sender: Bool
        let label: String
        let value: String
        
        var body: some View {
            Group {
                if sender {
                    HStack {
                        Spacer()
                        Text("@**\(label)** \(value)")
                            .foregroundStyle(.white)
                            .padding(.init(horizontal: 8, vertical: 6))
                            .background {
                                Capsule(style: .continuous)
                                    .fill(Color.blue)
                            }
                    }
                    .padding(.bottom, 6)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(value)
                                .padding(.init(horizontal: 8, vertical: 6))
                                .background {
                                    Capsule(style: .continuous)
                                        .fill(Color.gray.opacity(0.2))
                                }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 6)
                }
            }
        }
    }
}

private func log(_ label: String, _ value: String, _ sender: Bool) {
    Console.shared.logs.append(.init(sender: sender, label: label, value: value))
}

private func propose(_ label: String, _ value: String) {
    log(label, value, true)
}

private func report(_ label: String, _ value: String) {
    log(label, value, false)
}

extension View {
    func logSizes(_ label: String) -> some View {
        LayoutCoordinator(
            onProposal: {
                propose(label, $0.pretty)
            }, onResult: {
                report(label, $0.pretty)
            }) { self }
    }
    
    func clearConsole() -> some View {
        LayoutCoordinator(
            onProposal: { _ in
                Console.shared.logs.removeAll()
            }, onResult: nil
        ) { self }
    }
}

struct LayoutCoordinator: Layout {
    let onProposal: (ProposedViewSize) -> Void
    var onResult: ((CGSize) -> Void)? = nil
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        assert(subviews.count == 1)
        onProposal(proposal)
        let result = subviews[0].sizeThatFits(proposal)
        onResult?(result)
        return result
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

extension CGFloat {
    var pretty: String {
        let result = String(format: "%.2f", self)
        if result.hasSuffix(".00") {
            return String(result.dropLast(3))
        }
        return result
    }
}

extension Optional where Wrapped == CGFloat {
    var pretty: String {
        self?.pretty ?? "nil"
    }
}

extension CGSize {
    var pretty: String {
        [width, height].map({ $0.pretty }).joined(separator: " · ")
    }
}

extension ProposedViewSize {
    var pretty: String {
        [width, height].map({ $0.pretty }).joined(separator: " · ")
    }
}

struct LayoutInspector: View {
    @State private var proposedSize: CGSize = CGSize(width: 200, height: 100)
    @State private var maximumWidth: CGFloat = 200.0
    
    let console = Console.shared
    
    var subject: some View {
        HStack {
            Rectangle()
                .fill(.orange)
                .logSizes("Orange")
            Text("Hello, World!")
                .logSizes("Text")
            Rectangle()
                .fill(.red)
                .frame(minWidth: 80)
                .logSizes("Red")
        }
        .logSizes("HStack")
    }
    
    var body: some View {
        VStack {
            ZStack {
                subject
                    .clearConsole()
                    .frame(width: proposedSize.width, height: proposedSize.height)
                    .border(.blue)
            }
            .frame(maxHeight: .infinity)
            Slider(
                value: $proposedSize.width,
                in: 0...maximumWidth,
                label: { Spacer() },
                minimumValueLabel: {
                    Image(systemName: "rectangle.portrait")
                },
                maximumValueLabel: {
                    Image(systemName: "rectangle")
                }
            )
            .padding(20)
            ScrollView {
                LazyVGrid(columns: [.init(.flexible(minimum: 0, maximum: .infinity))], spacing: 0) {
                    ForEach(console.logs) {
                        $0
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: {
            maximumWidth = $0
        }
    }
}

#Preview {
    LayoutInspector()
}
