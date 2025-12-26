//
//  AsyncTimeline.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/26/25.
//

import SwiftUI

struct Event: Identifiable, Hashable, Sendable {
    let id: Int
    let time: TimeInterval
    let color: Color
    let value: Value
}

enum Value: Hashable, Sendable {
    case int(Int)
    case string(String)
}

let sampleInt: [Event] = [
    .init(id: 0, time: 0, color: .red, value: .int(1)),
    .init(id: 1, time: 1, color: .red, value: .int(2)),
    .init(id: 2, time: 2, color: .red, value: .int(3)),
    .init(id: 3, time: 5, color: .red, value: .int(4)),
    .init(id: 4, time: 8, color: .red, value: .int(5))
]

let sampleString: [Event] = [
    .init(id: 100_0, time: 1.5, color: .blue, value: .string("a")),
    .init(id: 100_1, time: 2.5, color: .blue, value: .string("b")),
    .init(id: 100_2, time: 4.5, color: .blue, value: .string("c")),
    .init(id: 100_3, time: 6.5, color: .blue, value: .string("d")),
    .init(id: 100_4, time: 7.5, color: .blue, value: .string("e"))
]

extension Value: View {
    var body: some View {
        switch self {
        case .int(let i): Text(i.description)
        case .string(let s): Text(s)
        }
    }
}

struct Timed: ViewModifier {
    let duration: TimeInterval
    let containerSize: CGSize
    let time: TimeInterval
    let size: CGSize
    
    func body(content: Content) -> some View {
    }
}

struct TimelineView: View {
    let events: [Event]
    let duration: TimeInterval
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary)
                    .frame(height: 1)
                ForEach(0...Int(duration.rounded(.up)), id: \.self) { tick in
                    Rectangle()
                        .frame(width: 1)
                        .foregroundStyle(.secondary)
                        .alignmentGuide(.leading) { _ in
                            (30 - proxy.size.width) * (Double(tick) / duration)
                        }
                }
                .offset(x: 15)
                ForEach(events) { event in
                    event.value
                        .frame(width: 30, height: 30)
                        .background {
                            Circle().fill(event.color)
                        }
                        .alignmentGuide(.leading) { _ in
                            (30 - proxy.size.width) * (event.time / duration)
                        }
                }
            }
        }
        .frame(height: 30)
    }
}

struct AsyncTimelineDemo: View {
    var duration: TimeInterval {
        max(sampleInt.last!.time, sampleString.last!.time)
    }
    
    var body: some View {
        VStack {
            TimelineView(events: sampleInt, duration: duration)
            TimelineView(events: sampleString, duration: duration)
        }
        .padding(20)
    }
}

#Preview {
    AsyncTimelineDemo()
}
