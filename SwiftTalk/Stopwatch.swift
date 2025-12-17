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
    let startTime: CFTimeInterval
    var endTime = CACurrentMediaTime()
    var level: Level = .regular
    
    var timeInterval: CFTimeInterval {
        endTime - startTime
    }
    
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
    private(set) var isRunning: Bool = false
    private(set) var laps: [Lap] = []
    
    @ObservationIgnored
    private var timer: Timer?
    
    var totalDuration: Duration {
        .seconds(totalTime)
    }
    
    var totalTime: Double {
        laps.last.map({ CACurrentMediaTime() - $0.startTime }) ?? 0
    }
    
    var lapTime: Double? {
        guard laps.count > 1 else {
            return nil
        }
        return laps.first?.timeInterval
    }
    
    func stop() {
        isRunning = false
        stopTimer()
    }
    
    func start() {
        if !hasLaps {
            let startTime = CACurrentMediaTime()
            self.laps = [Lap(index: 1, startTime: startTime)]
        }
        isRunning = true
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
            guard let self else { return }
            guard self.hasLaps else { return }
            
            var lap = self.laps[0]
            lap.endTime = CACurrentMediaTime()
            self.laps[0] = lap
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    func recordLap() {
        var laps = self.laps
        if let lap = laps.first {
            let new = Lap(index: laps.count+1, startTime: lap.endTime)
            laps.insert(new, at: 0)
        }
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

struct Clock: View {
    enum Style: Int, CaseIterable, Identifiable {
        case digital, analog
        
        var id: Self { self }
    }
    
    let stopwatch: Stopwatch
    let style: Style
    
    func tick(at tick: Int) -> some View {
        VStack {
            Rectangle()
                .fill(Color.white.opacity(tick % 20 == 0 ? 1 : 0.4))
                .frame(width: 2, height: (tick % 4 == 0 ? 12 : 6))
            Spacer()
        }
        .rotationEffect(.degrees(Double(tick)/240.0 * 360.0))
    }
    
    var body: some View {
        switch style {
        case .digital:
            Text(stopwatch.totalDuration, format: Stopwatch.durationTimeFormat)
                .lineLimit(1)
                .font(.system(size: 100, weight: .thin))
                .minimumScaleFactor(0.1)
                .monospacedDigit()
//                .border(Color.red)
        case .analog:
            ZStack {
                ForEach(0..<240) {
                    tick(at: $0)
                }
                stopwatch.lapTime.map({
                    Pointer()
                        .stroke(Color.blue, lineWidth: 2)
                        .rotationEffect(.degrees($0 * 6))
                })
                Pointer()
                    .stroke(Color.orange, lineWidth: 2)
                    .rotationEffect(.degrees(stopwatch.totalTime * 6))
                Color.clear
            }
            .aspectRatio(1, contentMode: .fill)
//            .border(Color.blue)
            .padding(30)
            .padding(.bottom, 50)
        }
    }
}

struct StopwatchPage: View {
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
        .aspectRatio(1, contentMode: .fill)
//        .border(Color.green)
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
//        .border(.yellow)
    }
    
    var body: some View {
        VStack {
            header
            table
        }
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
