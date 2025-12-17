//
//  Stopwatch.swift
//  SwiftTalk
//
//  Created by 程東 on 12/16/25.
//

import SwiftUI
import Observation

struct Lap: Equatable {
    let index: Int
    var timeInterval: CFTimeInterval = 0
    var level: Level = .regular
    
    var duration: Duration {
        .seconds(timeInterval)
    }
    
    enum Level {
        case regular, shortest, longest
        
        var color: Color {
            switch self {
            case .regular:  .init(uiColor: .label)
            case .shortest: .green
            case .longest:  .red
            }
        }
    }
}

extension Lap: Comparable {
    static func < (lhs: Lap, rhs: Lap) -> Bool {
        lhs.timeInterval < rhs.timeInterval
    }
}

@Observable
class Stopwatch {
    private var startTime: CFTimeInterval?
    private var additionalTime: CFTimeInterval = 0
    
    private(set) var laps: [Lap] = []
    
    @ObservationIgnored
    private var timer: Timer?
    
    var isRunning: Bool {
        startTime != nil
    }
    
    var totalDuration: Duration {
        .seconds(totalTime)
    }
    
    var totalTime: Double {
        laps.reduce(into: 0, { accu, next in
            accu += next.timeInterval
        })
    }
    
    var lapTime: Double? {
        guard laps.count > 1 else {
            return nil
        }
        return laps.first?.timeInterval
    }
    
    func stop() {
        startTime = nil
        additionalTime = laps[0].timeInterval        
        stopTimer()
    }
    
    func start() {
        if !hasLaps {
            self.laps = [Lap(index: 1, timeInterval: 0)]
        }
        startTime = CACurrentMediaTime() - additionalTime
        additionalTime = 0
        startTimer()
    }
    
    func reset() {
        laps.removeAll()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startTimer() {
        let timer = Timer(timeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self, let startTime else { return }
            self.laps[0].timeInterval = CACurrentMediaTime() - startTime
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    func recordLap() {
        self.startTime = CACurrentMediaTime()
        self.laps.insert(Lap(index: laps.count+1), at: 0)
        
        var laps = self.laps

        if laps.count > 2 {
            var sample = Array(laps.dropFirst())
            if let max = sample.max(), let min = sample.min(), max != min {
                sample.enumerated().forEach { index, item in
                    sample[index].level = switch item {
                    case max: .longest
                    case min: .shortest
                    default: .regular
                    }
                }
            }
            laps = [laps[0]] + sample
        }
        
        self.laps = laps
    }
    
    var hasLaps: Bool {
        !laps.isEmpty
    }
    
    var showLapButton: Bool {
        isRunning || !hasLaps
    }
    
    static var durationTimeFormat: Duration.TimeFormatStyle {
        .time(pattern: .minuteSecond(
            padMinuteToLength: 2,
            fractionalSecondsLength: 2
        ))
    }
}

extension View {
    func visible(_ condition: Bool) -> some View {
        opacity(condition ? 1 : 0)
    }
}

extension CGRect {
    var center: CGPoint {
        .init(x: midX, y: midY)
    }
    
    init(center: CGPoint, radius: CGFloat) {
        self = .init(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2.0,
            height: radius * 2.0
        )
    }
}

struct Pointer: Shape {
    let circleRadius: CGFloat = 3.0
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: .init(x: rect.midX, y: rect.minY))
            p.addLine(to: .init(x: rect.midX, y: rect.midY - circleRadius))
            p.addEllipse(in: .init(center: rect.center, radius: circleRadius))
            p.move(to: .init(x: rect.midX, y: rect.midY + circleRadius))
            p.addLine(to: .init(x: rect.midX, y: rect.midY + rect.height / 10.0))
        }
    }
}

extension CGPoint {
    init(angle: Angle, distance: CGFloat) {
        self.init(
            x: CGFloat(cos(angle.radians)) * distance,
            y: CGFloat(sin(angle.radians)) * distance
        )
    }
    
    var size: CGSize {
        .init(width: x, height: y)
    }
}

struct AnalogClockLabels: View {
    let numbers: [Int]
    
    var body: some View {
        GeometryReader { proxy in
            let radius = proxy.size.width / 2.0
                        
            ZStack {
                ForEach(numbers.enumerated(), id: \.offset) { idx, item in
                    let degrees = 360 * Double(idx) / Double(numbers.count) - 90.0
                    let point = CGPoint(angle: .degrees(degrees), distance: radius)
                    
                    Text(item.description)
                        .offset(point.size)
                }
                Color.clear
            }.aspectRatio(1, contentMode: .fit)
        }
    }
}

struct AnalogClockTicks: View {
    let numberOfMajorTick: Int
    let subdivisionCount: Int
    let majorTickSize: CGSize
    
    var numberOfMajorAndMinorTicks: Int {
        numberOfMajorTick * subdivisionCount
    }
    
    func tick(at index: Int) -> some View {
        VStack {
            Rectangle()
                .fill(Color.white.opacity(index % (5 * subdivisionCount) == 0 ? 1 : 0.4))
                .frame(
                    width: majorTickSize.width,
                    height: (index % subdivisionCount == 0 ? 1 : 0.5) * majorTickSize.height
                )
            Spacer()
        }
        .rotationEffect(.degrees(Double(index)/Double(numberOfMajorAndMinorTicks) * 360.0))
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(0..<numberOfMajorAndMinorTicks), id: \.self) {
                tick(at: $0)
            }
            Color.clear
        }.aspectRatio(1, contentMode: .fit)
    }
}

struct AnalogClock: View {
    let stopwatch: Stopwatch
    
    var body: some View {
        ZStack {
            ZStack {
                AnalogClockTicks(
                    numberOfMajorTick: 60,
                    subdivisionCount: 5,
                    majorTickSize: .init(width: 2, height: 14)
                )
                AnalogClockLabels(
                    numbers: [60] + stride(from: 5, through: 55, by: 5)
                )
                .font(.title)
                .padding(35)
            }.overlay {
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        AnalogClockTicks(
                            numberOfMajorTick: 30,
                            subdivisionCount: 2,
                            majorTickSize: .init(width: 2, height: 10)
                        )
                        AnalogClockLabels(
                            numbers: [30] + stride(from: 5, through: 25, by: 5)
                        )
                        .fontWeight(.regular)
                        .padding(22)
                        Pointer()
                            .stroke(Color.orange, lineWidth: 1.5)
                            .rotationEffect(.degrees(stopwatch.totalTime * (360 / (60 * 30))))
                    }
                    .frame(width: 90, height: 90)
                    .padding(.bottom, 12)
                    Spacer()
                    HStack {
                        Spacer()
                        Text(stopwatch.totalDuration, format: Stopwatch.durationTimeFormat)
                            .font(.system(size: 24))
                            .monospacedDigit()
                        Spacer()
                    }
                    .padding(.bottom, 12)
                    Spacer()
                }
            }
            stopwatch.lapTime.map({
                Pointer()
                    .stroke(Color.blue, lineWidth: 2)
                    .rotationEffect(.degrees($0 * (360 / 60)))
            })
            Pointer()
                .stroke(Color.orange, lineWidth: 2)
                .rotationEffect(.degrees(stopwatch.totalTime * (360 / 60)))
            Color.clear
        }.aspectRatio(1, contentMode: .fit)
    }
}

extension View {
    func flexible(weight: Font.Weight = .regular, baseSize: CGFloat = 100) -> some View {
        font(.system(size: baseSize, weight: weight))
            .minimumScaleFactor(0.01)
            .lineLimit(1)
    }
}

struct Clock: View {
    enum Style: String, CaseIterable, Identifiable {
        case digital, analog
        
        var id: Self { self }
    }
    
    let stopwatch: Stopwatch
    let style: Style
    
    var body: some View {
        switch style {
        case .digital:
            VStack {
                Spacer()
                Text(stopwatch.totalDuration, format: Stopwatch.durationTimeFormat)
                    .flexible(weight: .thin)
                    .monospacedDigit()
                Spacer()
            }
        case .analog:
            AnalogClock(stopwatch: stopwatch)
                .scaleEffect(.init(width: 0.85, height: 0.85))
        }
    }
}

struct StopwatchPage: View {
    @State private var containerWidth: CGFloat = 0
    @State private var maxLabelSize: CGFloat = 0
    @State private var selectedStyle: Clock.Style = .digital
    private let stopwatch = Stopwatch()
    
    var header: some View {
        TabView(selection: $selectedStyle) {
            ForEach(Clock.Style.allCases) { style in
                Clock(stopwatch: stopwatch, style: style)
                    .tag(style)
            }
        }
        .tabViewStyle(.page)
        .overlay(alignment: .bottom) {
            actionStack
        }
        .padding(.horizontal)
        .frame(height: containerWidth)
    }
    
    private var actionStack: some View {
        HStack {
            ZStack {
                Button {
                    stopwatch.recordLap()
                } label: {
                    Text("Lap")
                        .modifier(SyncSize(maxSize: $maxLabelSize))
                }
                .disabled(!stopwatch.isRunning)
                .visible(stopwatch.showLapButton)
                Button {
                    stopwatch.reset()
                } label: {
                    Text("Reset")
                        .modifier(SyncSize(maxSize: $maxLabelSize))
                }
                .visible(!stopwatch.showLapButton)
            }
            .foregroundStyle(.white)
            
            Spacer()
            
            ZStack {
                Button {
                    stopwatch.stop()
                } label: {
                    Text("Stop")
                        .modifier(SyncSize(maxSize: $maxLabelSize))
                }
                .foregroundStyle(.red)
                .visible(stopwatch.isRunning)
                Button {
                    stopwatch.start()
                } label: {
                    Text("Start")
                        .modifier(SyncSize(maxSize: $maxLabelSize))
                }
                .foregroundStyle(.green)
                .visible(!stopwatch.isRunning)
            }
        }
        .buttonStyle(CircleStyle())
    }
    
    var table: some View {
        List {
            ForEach(stopwatch.laps, id: \.index) { lap in
                HStack {
                    Text("Lap \(lap.index)")
                    Spacer()
                    Text(lap.duration, format: Stopwatch.durationTimeFormat)
                        .monospacedDigit()
                }.foregroundStyle(lap.level.color)
            }
        }
        .listStyle(.plain)
    }
    
    var body: some View {
        VStack {
            header
            table
        }
        .onGeometryChange(for: CGSize.self, of: { $0.size }, action: {
            self.containerWidth = $0.width
        })
        .preferredColorScheme(.dark)
    }
}

struct CircleStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(20)
            .background {
                Circle()
                    .fill()
                    .opacity(configuration.isPressed || !isEnabled ? 0.1 : 0.2)
                    .saturation(isEnabled ? 1.0 : 0.0)
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

struct SyncSize: ViewModifier {
    @Binding var maxSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { proxy in
                max(proxy.size.width, proxy.size.height)
            } action: { newValue in
                if newValue > maxSize {
                    maxSize = newValue
                }
            }
            .frame(
                minWidth: maxSize > 0 ? maxSize : nil,
                minHeight: maxSize > 0 ? maxSize : nil
            )
    }
}

#Preview {
    StopwatchPage()
}
