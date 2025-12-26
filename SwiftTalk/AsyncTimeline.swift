//
//  AsyncTimeline.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/26/25.
//

import SwiftUI
import AsyncAlgorithms

struct Event: Identifiable, Hashable, Sendable {
    var id: EventID = .single(UUID())
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
    indirect case combined(Value, Value)
}

indirect enum EventID: Hashable, Sendable {
    case single(UUID)
    case combined(EventID, EventID)
}

private let sampleInt: [Event] = [
    .init(time: 0, color: .red, value: .int(1)),
    .init(time: 1, color: .red, value: .int(2)),
    .init(time: 2, color: .red, value: .int(3)),
    .init(time: 5, color: .red, value: .int(4)),
    .init(time: 8, color: .red, value: .int(5))
]

private let sampleString: [Event] = [
    .init(time: 1.5, color: .blue, value: .string("a")),
    .init(time: 2.5, color: .blue, value: .string("b")),
    .init(time: 4.5, color: .blue, value: .string("c")),
    .init(time: 6.5, color: .blue, value: .string("d")),
    .init(time: 7.5, color: .blue, value: .string("e"))
]

extension Value: View {
    var body: some View {
        switch self {
        case .int(let i): Text(i.description)
        case .string(let s): Text(s)
        case .combined(let lhs, let rhs):
            HStack(spacing: 0) {
                lhs
                rhs
            }
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

struct TimedEventStream: AsyncSequence, Sendable {
    typealias Element = Event
    let events: [Event]
    let speed: TimeInterval
    
    nonisolated func makeAsyncIterator() -> AsyncStream<Event>.Iterator {
        AsyncStream { continuation in
            let sortedEvents = events.sorted()
            let task = Task {
                let start = Date()
                for event in sortedEvents {
                    let interval = event.time / speed
                    let diff = Date().timeIntervalSince(start)
                    if interval > diff {
                        try? await Task.sleep(nanoseconds: UInt64((interval - diff) * 1_000_000_000))
                    }
                    continuation.yield(event)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }.makeAsyncIterator()
    }
}

extension Array where Element == Event {
    func stream(speed: TimeInterval = 1.0) -> TimedEventStream {
        TimedEventStream(events: self, speed: speed)
    }
}

func run(algorithm: Algorithm, _ lhs: [Event], _ rhs: [Event]) async -> [Event] {
    let speed: Double = 10
    let lhs = lhs.stream(speed: speed)
    let rhs = rhs.stream(speed: speed)
    
    var result: [Event] = []
    let start = Date()
    var interval: TimeInterval {
        Date().timeIntervalSince(start) * speed
    }
    switch algorithm {
    case .merge:
        for await event in merge(lhs, rhs) {
            result.append(.init(id: event.id, time: interval, color: event.color, value: event.value))
        }
    case .chain:
        for await event in chain(lhs, rhs) {
            result.append(.init(id: event.id, time: interval, color: event.color, value: event.value))
        }
    case .zip:
        for await (e0, e1) in zip(lhs, rhs) {
            result.append(.init(id: .combined(e0.id, e1.id), time: interval, color: .green, value: .combined(e0.value, e1.value)))
        }
    case .combineLatest:
        for await (e0, e1) in combineLatest(lhs, rhs) {
            result.append(.init(id: .combined(e0.id, e1.id), time: interval, color: .green, value: .combined(e0.value, e1.value)))
        }
    case .adjacentPairs:
        for await (e0, e1) in lhs.adjacentPairs() {
            result.append(.init(id: .combined(e0.id, e1.id), time: interval, color: .green, value: .combined(e0.value, e1.value)))
        }
    }
    return result
}

enum Algorithm: String, CaseIterable, Identifiable {
    case merge, chain, zip, combineLatest, adjacentPairs
    
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
            if algorithm != .adjacentPairs {
                TimelineView(events: $sample1, duration: duration)
            }
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
    @State private var selection: Algorithm = .merge
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(Algorithm.allCases) { algorithm in
                VStack {
                    Text(algorithm.rawValue)
                        .font(.largeTitle)
                    AsyncAlgorithm(algorithm: algorithm)
                    Divider()
                }
                .tag(algorithm)
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    AsyncTimelineDemo()
}
