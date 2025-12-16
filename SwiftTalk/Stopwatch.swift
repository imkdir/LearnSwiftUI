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
    
    var timeInterval: CFTimeInterval {
        endTime - startTime
    }
    
    var duration: Duration {
        .seconds(timeInterval)
    }
    
    static var format: Duration.TimeFormatStyle {
        .time(pattern: .minuteSecond(
            padMinuteToLength: 2,
            fractionalSecondsLength: 2
        ))
    }
}

@Observable
class Stopwatch {
    private(set) var isRunning: Bool = false
    private(set) var laps: [Lap] = []
    
    @ObservationIgnored
    private var displayLink: CADisplayLink?
    
    var totalDuration: Duration {
        .seconds(laps.reduce(into: 0, { accu, next in
            accu += next.timeInterval
        }))
    }
    
    func toggle() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
        isRunning.toggle()
    }
    
    private func startTimer() {
        if laps.isEmpty {
            recordLap()
        }
        let proxy = WeakProxy(target: self)
        let displayLink = CADisplayLink(
            target: proxy,
            selector: #selector(WeakProxy.handleFrame(_:))
        )
        displayLink.preferredFrameRateRange = .init(
            minimum: 20, maximum: 30, preferred: 20
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }
    
    fileprivate func updateFrame() {
        guard hasLaps else { return }
        
        var lap = laps[0]
        lap.endTime = CACurrentMediaTime()
        laps[0] = lap
    }
    
    private func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func recordLap() {
        if let lap = laps.first {
            let new = Lap(index: laps.count+1, startTime: lap.endTime)
            laps.insert(new, at: 0)
        } else {
            laps.append(.init(index: 1, startTime: CACurrentMediaTime()))
        }
    }
    
    func resetLaps() {
        laps.removeAll()
    }
    
    var hasLaps: Bool {
        !laps.isEmpty
    }
    
    private class WeakProxy {
        weak var target: Stopwatch?
        
        init(target: Stopwatch) {
            self.target = target
        }
        
        @objc
        func handleFrame(_ link: CADisplayLink) {
            if let target {
                target.updateFrame()
            } else {
                link.invalidate()
            }
        }
    }
}

struct StopwatchPage: View {
    @State private var maxLabelSize: CGFloat = 0
    private let stopwatch = Stopwatch()
    
    
    
    var header: some View {
        VStack {
            Spacer()
            Text(stopwatch.totalDuration, format: Lap.format)
                .lineLimit(1)
                .font(.system(size: 100, weight: .thin))
                .minimumScaleFactor(0.1)
                .monospacedDigit()
            Spacer()
            HStack {
                if stopwatch.isRunning {
                    Button {
                        stopwatch.recordLap()
                    } label: {
                        Text("Lap")
                            .modifier(SyncSize(maxSize: $maxLabelSize))
                    }
                    .foregroundStyle(.white)
                } else {
                    Button {
                        stopwatch.resetLaps()
                    } label: {
                        Text(stopwatch.hasLaps ? "Reset" : "Lap")
                            .modifier(SyncSize(maxSize: $maxLabelSize))
                    }
                    .disabled(!stopwatch.hasLaps)
                    .foregroundStyle(.white)
                }
                
                Spacer()
                
                Button {
                    stopwatch.toggle()
                } label: {
                    Text(stopwatch.isRunning ? "Stop" : "Start")
                        .modifier(SyncSize(maxSize: $maxLabelSize))
                }
                .foregroundStyle(stopwatch.isRunning ? .red : .green)
            }
            .buttonStyle(CircleStyle())
        }
        .padding()
    }
    
    var body: some View {
        VStack {
            header
            List {
                ForEach(stopwatch.laps, id: \.index) { lap in
                    HStack {
                        Text("Lap \(lap.index)")
                        Spacer()
                        Text(lap.duration, format: Lap.format)
                            .monospacedDigit()
                    }
                }
            }
            .listStyle(.plain)
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
