//
//  AsyncTimeline.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/26/25.
//

import SwiftUI
import AsyncAlgorithms

struct Event: Identifiable, Hashable, Sendable {
    let id: Int
    var time: TimeInterval
    let color: Color
    let value: Value
}

extension Event: Comparable {
    static func < (lhs: Event, rhs: Event) -> Bool {
        lhs.time < rhs.time
    }
}

extension EnvironmentValues {
    @Entry var secondsPerPoint: CGFloat = 0
}

struct EventNode: View {
    @Binding var event: Event
    @GestureState private var offset: CGFloat = 0
    @Environment(\.secondsPerPoint) private var scale
    
    var gesture: some Gesture {
        DragGesture()
            .updating($offset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                event.time += value.translation.width * scale
            }
    }
    
    var body: some View {
        event.value
            .frame(width: 30, height: 30)
            .background {
                Circle().fill(event.color)
            }
            .offset(x: offset)
            .gesture(gesture)
    }
}

enum Value: Hashable, Sendable {
    case int(Int)
    case string(String)
}

private let sampleInt: [Event] = [
    .init(id: 0, time: 0, color: .red, value: .int(1)),
    .init(id: 1, time: 1, color: .red, value: .int(2)),
    .init(id: 2, time: 2, color: .red, value: .int(3)),
    .init(id: 3, time: 5, color: .red, value: .int(4)),
    .init(id: 4, time: 8, color: .red, value: .int(5))
]

private let sampleString: [Event] = [
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

struct TimelineView: View {
    @Binding var events: [Event]
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
                ForEach($events) { $event in
                    EventNode(event: $event)
                        .alignmentGuide(.leading) { _ in
                            (30 - proxy.size.width) * (event.time / duration)
                        }
                }
            }
            .environment(\.secondsPerPoint, duration/(proxy.size.width-30))
        }
        .frame(height: 30)
    }
}

extension Array where Element == Event {
    @MainActor
    func stream(speed: TimeInterval = 1.0) -> AsyncStream<Event> {
        AsyncStream { continuation in
            sorted().enumerated().forEach { idx, event in
                Timer.scheduledTimer(withTimeInterval: event.time / speed, repeats: false) { _ in
                    continuation.yield(event)
                    if idx == count - 1 {
                        continuation.finish()
                    }
                }
            }
        }
    }
}

func run(algorithm: Algorithm, _ lhs: [Event], _ rhs: [Event]) async -> [Event] {
    let speed: Double = 10
    let lhs = lhs.stream(speed: speed)
    let rhs = rhs.stream(speed: speed)
    
    switch algorithm {
    case .merge:
        let merged = merge(lhs, rhs)
        return await Array(merged)
    case .chain:
        var result: [Event] = []
        let start = Date()
        for await event in chain(lhs, rhs) {
            let interval = Date().timeIntervalSince(start) * speed
            result.append(.init(id: event.id, time: interval, color: event.color, value: event.value))
        }
        return result
    }
}

enum Algorithm: String, CaseIterable, Identifiable {
    case merge, chain
    
    var id: Self { self }
}

struct AsyncAlgorithm: View {
    let algorithm: Algorithm
    
    @State private var sample0: [Event] = sampleInt
    @State private var sample1: [Event] = sampleString
    @State private var results: [Event]? = nil
    @State private var loading: Bool = false
    
    var duration: TimeInterval {
        (sample0 + sample1 + (results ?? []))
            .lazy.map({ $0.time })
            .max() ?? 1.0
    }
    
    var body: some View {
        VStack {
            TimelineView(events: $sample0, duration: duration)
            TimelineView(events: $sample1, duration: duration)
            TimelineView(events: .constant(results ?? []), duration: duration)
                .opacity(loading ? 0.5 : 1.0)
                .animation(.default, value: results)
        }
        .padding(20)
        .task(id: sample0 + sample1) {
            loading = true
            results = await run(algorithm: algorithm, sample0, sample1)
            loading = false
        }
    }
}

struct AsyncTimelineDemo: View {
    
    var body: some View {
        VStack {
            ForEach(Algorithm.allCases) {
                Text($0.rawValue)
                    .padding(4)
                    .border(.secondary)
                AsyncAlgorithm(algorithm: $0)
                Divider()
            }
        }
    }
}

#Preview {
    AsyncTimelineDemo()
}
