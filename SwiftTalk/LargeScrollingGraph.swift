//
//  LargeScrollingGraph.swift
//  SwiftTalk
//
//  Created by D CHENG on 12/24/25.
//

import SwiftUI

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double // 0...1
}

struct Day: Identifiable {
    let values: [DataPoint]
    let startOfDay: Date
    
    var id: Date {
        startOfDay
    }
}

extension LargeScrollingGraph {
    final class Model {
        var days: [Day] = []
        
        static let shared = Model()
        
        init() {
            generateRandomValues()
        }
        
        func generateRandomValues() {
            var lastDate = Date()
            let values: [DataPoint] = (0..<100_000).map({ x in
                let ri = 60 * 60 * .random(in: 0.5...3.0)
                lastDate.addTimeInterval(-ri)
                return .init(date: lastDate, value: .random(in: 0...1))
            }).reversed()
            
            var current = Calendar.current.startOfDay(for: values[0].date)
            var next: Date { current.addingTimeInterval(3600 * 24) }
            var dayValues: [DataPoint] = []
            for value in values {
                if value.date >= next {
                    days.append(.init(values: dayValues, startOfDay: current))
                    dayValues = []
                    current = next
                }
                dayValues.append(value)
            }
            if !dayValues.isEmpty {
                days.append(.init(values: dayValues, startOfDay: current))
            }
        }
    }
    
}

extension DataPoint {
    func point(in day: Day) -> UnitPoint {
        let x = date.timeIntervalSince(day.startOfDay) / 86400.0
        let y = 1 - value
        return UnitPoint(x: x, y: y)
    }
}

func *(lhs: UnitPoint, rhs: CGSize) -> CGPoint {
    .init(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

struct Line: Shape, Identifiable {
    let id = UUID()
    let from: UnitPoint
    let to: UnitPoint
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: rect.origin + from * rect.size)
            p.addLine(to: rect.origin + to * rect.size)
        }
    }
}

struct Point: View, Identifiable {
    let id = UUID()
    let offset: CGPoint
    
    var body: some View {
        Circle()
            .frame(width: 4, height: 4)
            .offset(x: offset.x - 2, y: offset.y - 2)
    }
}

extension Day {
    func lines(with nextDay: Day?) -> [Line] {
        var result = zip(values, values.dropFirst())
            .map({ (lhs, rhs) in
                Line(
                    from: lhs.point(in: self),
                    to: rhs.point(in: self)
                )
            })
        
        if let lhs = values.last,
           let rhs = nextDay?.values.first {
            result.append(.init(
                from: lhs.point(in: self),
                to: rhs.point(in: self)
            ))
        }
        
        return result
    }
    
    func points(in size: CGSize) -> [Point] {
        values.map({
            .init(offset: $0.point(in: self) * size)
        })
    }
}

struct DayView: View, Identifiable {
    let day: Day
    let nextDay: Day?
    
    var id: Day.ID {
        day.id
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    ForEach(day.lines(with: nextDay)) {
                        $0
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.red)
                    }
                    ForEach(day.points(in: proxy.size)) {
                        $0
                            .foregroundStyle(.orange)
                    }
                }
            }
            Text(day.startOfDay, style: .date)
        }
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: DayViewMidXPreference.self,
                    value: [
                        day.startOfDay: proxy.frame(in: .global).midX
                    ])
            }
        }
    }
}

extension LargeScrollingGraph.Model {
    
    var daysWithNexDay: [(Day, Day?)] {
        var zipped: [(Day, Day?)] = Array(zip(days, days.dropFirst()))
        if let last = days.last {
            zipped.append((last, nil))
        }
        return zipped
    }
    
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct DayViewMidXPreference: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    
    static func reduce(value: inout [Date : CGFloat], nextValue: () -> [Date : CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct DateChange: Equatable {
    var value: Date
    var source: Source
    
    enum Source: String {
        case scroll, picker
    }
}

struct LargeScrollingGraph: View {
    
    @State private var dateChange = DateChange(
        value: Date().startOfDay,
        source: .picker
    )
    @State private var scrollViewMidX: CGFloat?
    
    private let model = Model.shared

    private var datePickerSelection: Binding<Date> {
        Binding {
            dateChange.value
        } set: { newValue in
            dateChange = DateChange(value: newValue.startOfDay, source: .picker)
        }
    }
    
    var dayViews: [DayView] {
        model.daysWithNexDay.map(DayView.init(day:nextDay:))
    }
    
    func centerMostDate(in visibleDays: [Date: CGFloat], to targetMidX: CGFloat) -> Date? {
        visibleDays
            .mapValues({ abs($0 - targetMidX) })
            .sorted(by: { $0.value < $1.value })
            .first?.key
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                ScrollViewReader { proxy in
                    LazyHStack(spacing: 2) {
                        ForEach(dayViews) {
                            $0
                                .frame(width: 300)
                                .border(.blue)
                                .id($0.id)
                        }
                    }
                    .onAppear {
                        model.days.last.map { day in
                            proxy.scrollTo(day.id, anchor: .center)
                        }
                    }
                    .onChange(of: dateChange) { _, newValue in
                        if case .picker = newValue.source {
                            withAnimation {
                                proxy.scrollTo(newValue.value, anchor: .center)
                            }
                        }
                    }
                }
            }.onGeometryChange(for: CGFloat.self) {
                $0.frame(in: .global).midX
            } action: { newValue in
                scrollViewMidX = newValue
            }
            .onPreferenceChange(DayViewMidXPreference.self) {
                if case .picker = dateChange.source {
                    return
                }
                if let midX = scrollViewMidX,
                   let date = centerMostDate(in: $0, to: midX) {
                    self.dateChange = .init(value: date, source: .scroll)
                }
            }
            .simultaneousGesture(DragGesture().onChanged({ _ in
                if case .picker = dateChange.source {
                    dateChange.source = .scroll
                }
            }))

            DatePicker("", selection: datePickerSelection, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
    }
}

#Preview {
    LargeScrollingGraph()
}
