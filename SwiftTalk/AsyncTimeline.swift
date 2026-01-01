//
//  AsyncTimeline.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/26/25.
//

import SwiftUI
import Combine
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

enum Value: Hashable, Sendable {
    case int(Int)
    case string(String)
    indirect case combined(Value, Value)
}

indirect enum EventID: Hashable, Sendable {
    case single(UUID)
    case combined(EventID, EventID)
}

extension EnvironmentValues {
    @Entry var secondsPerPoint: CGFloat = 0
}

private let itemSize = CGFloat(30)

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
            .frame(width: itemSize, height: itemSize)
            .background {
                Circle().fill(event.color)
            }
            .offset(x: offset)
            .gesture(gesture)
    }
}

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

struct Timeline: View {
    
    @Binding var events: [Event]
    let duration: TimeInterval
    
    var body: some View {
        GeometryReader { proxy in
            let contentSize = proxy.size.width - itemSize
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary)
                    .frame(height: 1)
                
                ForEach(0...Int(duration.rounded(.up)), id: \.self) { tick in
                    Rectangle()
                        .frame(width: 1)
                        .foregroundStyle(.secondary)
                        .alignmentGuide(.leading) { _ in
                            -contentSize * (Double(tick) / duration)
                        }
                }
                .offset(x: itemSize / 2.0)
                
                ForEach($events) { $event in
                    EventNode(event: $event)
                        .alignmentGuide(.leading) { _ in
                             -contentSize * (event.time / duration)
                        }
                }
            }
            .environment(\.secondsPerPoint, duration/contentSize)
        }
        .frame(height: 30)
    }
}

extension Array where Element == Event {
    @MainActor
    func stream(_ speed: TimeInterval) -> AsyncStream<Event> {
        AsyncStream { continuation in
            sorted().enumerated().forEach { idx, event in
                Timer.scheduledTimer(
                    withTimeInterval: event.time / speed,
                    repeats: false
                ) { _ in
                    continuation.yield(event)
                    if idx == count - 1 {
                        continuation.finish()
                    }
                }
            }
        }
    }
}

extension AsyncSequence {
    var stream: AsyncStream<Element> {
        var it = makeAsyncIterator()
        return AsyncStream<Element> {
            do {
                return try await it.next()
            } catch {
                fatalError()
            }
        }
    }
}

indirect enum Stream: Equatable {
    case input1
    case input2
    case merged(Stream, Stream)
    case chained(Stream, Stream)
    case zipped(Stream, Stream)
    case combinedLatest(Stream, Stream)
    case adjacentPaired(Stream)
}

extension Stream {
    
    struct Context {
        let lhs: [Event]
        let rhs: [Event]
        let speed: Double = 10.0
    }

    func drain(_ context: Context) async -> [Event] {
        var result: [Event] = []
        let start = Date()
        var interval: TimeInterval {
            Date().timeIntervalSince(start) * context.speed
        }
        for await event in await build(context) {
            result.append(.init(event: event, time: interval))
        }
        return result
    }
    
    @MainActor
    func build(_ context: Context) async -> AsyncStream<Event> {
        switch self {
        case .input1:
            return context.lhs.stream(context.speed)
            
        case .input2:
            return context.rhs.stream(context.speed)
            
        case .merged(let lhs, let rhs):
            async let as1 = lhs.build(context)
            async let as2 = rhs.build(context)
            
            return await merge(as1, as2).stream
            
        case .chained(let lhs, let rhs):
            async let as1 = lhs.build(context)
            async let as2 = rhs.build(context)
            
            return await chain(as1, as2).stream
            
        case .zipped(let lhs, let rhs):
            async let as1 = lhs.build(context)
            async let as2 = rhs.build(context)
            
            return await zip(as1, as2).map(+).stream
            
        case .combinedLatest(let lhs, let rhs):
            async let as1 = lhs.build(context)
            async let as2 = rhs.build(context)
            
            return await combineLatest(as1, as2).map(+).stream
            
        case .adjacentPaired(let val):
            async let result = val.build(context)
            
            return await result.adjacentPairs().map(+).stream
        }
    }
}

extension Event {
    static func +(lhs: Event, rhs: Event) -> Event {
        .init(
            id: .combined(lhs.id, rhs.id),
            time: 0,
            color: .purple,
            value: .combined(lhs.value, rhs.value)
        )
    }
    
    init(event: Event, time: TimeInterval) {
        self.id = event.id
        self.time = time
        self.color = event.color
        self.value = event.value
    }
}

extension Stream {
    
    var label: Text {
        switch self {
        case .input1:
            Text("input1").foregroundStyle(.red)
        case .input2:
            Text("input2").foregroundStyle(.blue)
        case .merged(let lhs, let rhs):
            Text("merge(\(lhs.label), \(rhs.label))")
        case .chained(let lhs, let rhs):
            Text("chain(\(lhs.label), \(rhs.label))")
        case .zipped(let lhs, let rhs):
            Text("zip(\(lhs.label), \(rhs.label))")
        case .combinedLatest(let lhs, let rhs):
            Text("combineLatest(\(lhs.label), \(rhs.label))")
        case .adjacentPaired(let stream):
            Text("\(stream.label).adjacentPairs")
        }
    }
}

struct UniqueStream: Equatable, Identifiable {
    let id = UUID()
    let stream: Stream
    
    nonisolated init(_ stream: Stream) {
        self.stream = stream
    }
}

struct StreamMap: View {
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif
    @State private var streams: [UniqueStream] = [
        .input2, .input1
    ].map(UniqueStream.init)
    @State private var selection: Set<UniqueStream.ID> = []
    
    @State private var sample1: [Event] = sampleInt
    @State private var sample2: [Event] = sampleString
    @State private var results: [UniqueStream.ID: [Event]] = [:]
    @State private var loading: Bool = false
    @State private var cancellables: Set<AnyCancellable> = []
    
    struct TaskID: Equatable {
        let events: [Event]
        let streams: [UniqueStream]
    }
    
    var duration: TimeInterval {
        (sample1 + sample2 + (results.values.flatMap({ $0 })))
            .lazy.map({ $0.time })
            .max() ?? 1.0
    }
    
    func events(_ id: UniqueStream.ID) -> Binding<[Event]> {
        .constant(results[id, default: []])
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                list
                actionStack
            }
            #if os(iOS)
            .environment(\.editMode, $editMode)
            .onChange(of: selection) { oldValue, newValue in
                if oldValue.isEmpty {
                    editMode = .active
                    DispatchQueue.main.async {
                        selection = newValue
                    }
                }
            }
            #endif
        }
    }
    
    var list: some View {
        List(streams, selection: $selection) { us in
            VStack(alignment: .leading) {
                switch us.stream {
                case .input1:
                    Timeline(events: $sample1, duration: duration)
                case .input2:
                    Timeline(events: $sample2, duration: duration)
                default:
                    Timeline(events: events(us.id), duration: duration )
                }
                us.stream.label
                    .font(.footnote)
            }
            .listRowBackground(Color.primary.opacity(0.1))
            .animation(.smooth, value: results)
        }
        .padding(20)
        .task(id: TaskID(events: sample1 + sample2, streams: streams)) {
            loading = true
            let context = Stream.Context(lhs: sample1, rhs: sample2)
            results = await withTaskGroup(of: (UUID, [Event]).self) { group in
                streams.forEach { us in
                    group.addTask {
                        (us.id, await us.stream.drain(context))
                    }
                }
                return await Dictionary(uniqueKeysWithValues: group)
            }
            loading = false
        }
    }
    
    func add(_ stream: Stream) {
        streams.insert(.init(stream), at: 0)
        #if os(iOS)
        editMode = .inactive
        #endif
    }
    
    var actionStack: some View {
        HStack {
            let selected = streams
                .filter({ selection.contains($0.id) })
            if selection.count == 1 {
                let stream = selected[0].stream
                Button {
                    add(stream)
                } label: {
                    Text("adjacentPairs")
                }
            } else if selection.count == 2 {
                let lhs = selected[0].stream
                let rhs = selected[1].stream
                Button { add(.merged(lhs, rhs)) } label: { Text("merge") }
                Button { add(.chained(lhs, rhs)) } label: { Text("chain") }
                Button { add(.zipped(lhs, rhs)) } label: { Text("zip") }
                Button { add(.combinedLatest(lhs, rhs)) } label: { Text("combineLatest") }
            }
            #if os(iOS)
            if editMode == .active || !selection.isEmpty {
                Button {
                    selection.removeAll()
                    editMode = .inactive
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.glass)
            }
            #endif
        }
        #if os(iOS)
        .buttonStyle(.glassProminent)
        #endif
    }
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


#Preview {
    StreamMap()
}
