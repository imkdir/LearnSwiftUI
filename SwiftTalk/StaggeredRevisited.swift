//
//  StaggeredStack.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/1/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var colorfulDelays: [Namespace.ID: Double] = [:]
}

private let colors: [Color] = [
    .red, .orange, .yellow, .green, .blue,
    .purple, .brown, .cyan, .teal, .indigo,
    .mint, .pink, .gray
]

private let icons: [String] = [
    // MARK: - Basic Movement
    "figure.stand",
    "figure.walk",
    "figure.run",
    "figure.fall",
    "figure.roll",
    
    // MARK: - Ball Sports
    "figure.american.football",
    "figure.australian.football",
    "figure.badminton",
    "figure.baseball",
    "figure.basketball",
    "figure.bowling",
    "figure.cricket",
    "figure.disc.sports",
    "figure.golf",
    "figure.handball",
    "figure.hockey",
    "figure.lacrosse",
    "figure.pickleball",
    "figure.racquetball",
    "figure.rugby",
    "figure.soccer",
    "figure.softball",
    "figure.squash",
    "figure.table.tennis",
    "figure.tennis",
    "figure.volleyball",
    "figure.waterpolo",
    
    // MARK: - Water & Ice Activities
    "figure.fishing",
    "figure.open.water.swim",
    "figure.pool.swim",
    "figure.sailing",
    "figure.surfing",
    "figure.water.fitness",
    "figure.curling",
    "figure.skating",
    "figure.skiing.crosscountry",
    "figure.skiing.downhill",
    "figure.snowboarding",
    
    // MARK: - Gym & Fitness
    "figure.cooldown",
    "figure.core.training",
    "figure.cross.training",
    "figure.elliptical",
    "figure.flexibility",
    "figure.highintensity.intervaltraining",
    "figure.indoor.cycle",
    "figure.jumprope",
    "figure.mixed.cardio",
    "figure.pilates",
    "figure.rolling",
    "figure.rower",
    "figure.stair.stepper",
    "figure.stairs",
    "figure.step.training",
    "figure.strengthtraining.traditional",
    "figure.yoga",
    
    // MARK: - Combat & Martial Arts
    "figure.boxing",
    "figure.fencing",
    "figure.kickboxing",
    "figure.martial.arts",
    "figure.wrestling",
    "figure.taichi",
    
    // MARK: - Outdoor & Recreation
    "figure.archery",
    "figure.climbing",
    "figure.equestrian.sports",
    "figure.hiking",
    "figure.hunting",
    "figure.outdoor.cycle",
    "figure.track.and.field",
    
    // MARK: - Lifestyle & Arts
    "figure.dance",
    "figure.socialdance",
    "figure.mind.and.body",
    "figure.play",
    
    // MARK: - Accessibility
    "figure.seated.seatbelt"
]

extension CGRect {
    var distance: CGFloat {
        sqrt(minX * minX + minY * minY)
    }
}

struct StaggerItem: Identifiable, View {
    let id = UUID()
    let icon = icons.randomElement() ?? "figure.walk"
    let color = colors.randomElement() ?? .black
    
    @State private var displayIconName: Bool = false
    
    struct Payload: Hashable, Comparable {
        let namespace: Namespace.ID
        let priority: Double
        let anchor: CGRect
        
        static func <(lhs: Payload, rhs: Payload) -> Bool {
            guard lhs.priority != rhs.priority else {
                return lhs.anchor.distance < rhs.anchor.distance
            }
            return lhs.priority > rhs.priority
        }
    }
    
    struct PayloadPreference: PreferenceKey {
        static var defaultValue: [Payload] = []
        
        static func reduce(value: inout [Payload], nextValue: () -> [Payload]) {
            value += nextValue()
        }
    }
    
    struct Parent: ViewModifier {
        @State private var remainingPayloads: [Payload] = []
        @State private var viewedIDs: Set<Namespace.ID> = []
        
        var sortedIDs: [Namespace.ID] {
            remainingPayloads
                .sorted()
                .map({ $0.namespace })
        }
        
        var delays: [Namespace.ID: Double] {
            Dictionary(
                uniqueKeysWithValues: sortedIDs
                    .enumerated()
                    .map({ ($1, Double($0) * 0.2) })
            )
        }
        
        func body(content: Content) -> some View {
            content
                .environment(\.colorfulDelays, delays)
                .onPreferenceChange(PayloadPreference.self) {
                    remainingPayloads = $0.filter({
                        !viewedIDs.contains($0.namespace)
                    })
                    viewedIDs.formUnion(remainingPayloads.map({ $0.namespace }))
                }
        }
    }
    
    struct Child<T: Transition>: ViewModifier {
        let transition: T
        let priority: Double
        
        @Namespace private var namespace
        @Environment(\.colorfulDelays) private var delays
        @State private var visible = false
        
        var delay: Double? {
            delays[namespace]
        }
        
        func body(content: Content) -> some View {
            transition
                .apply(content: content, phase: visible ? .identity : .willAppear)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: PayloadPreference.self, value: [.init(
                                namespace: namespace,
                                priority: priority,
                                anchor: proxy.frame(in: .global)
                            )])
                    }
                }
                .onChange(of: delay) { _, newValue in
                    if let newValue {
                        withAnimation(.smooth.delay(newValue)) {
                            visible = true
                        }
                    }
                }
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color.gradient)
            .frame(height: 80)
            .overlay {
                Group {
                    if displayIconName {
                        Text(icon)
                            .font(.callout)
                            .padding(4)
                            .transition(.scale)
                    } else {
                        Image(systemName: icon)
                            .font(.largeTitle)
                            .transition(.slide.combined(with: .opacity))
                    }
                }
                .foregroundStyle(.white)
            }
            .animation(.smooth, value: displayIconName)
            .onTapGesture {
                displayIconName.toggle()
            }
    }
}

extension View {
    func stagger<T: Transition>(_ transition: T, priority: Double = 0) -> some View {
        modifier(StaggerItem.Child(transition: transition, priority: priority))
    }
}

struct StaggeredRevisited: View {
    private let bannder = StaggerItem()
    @State private var items = (0...10).map({ _ in StaggerItem() })
    
    var columns: [GridItem] {
        [.init(.adaptive(minimum: 80), spacing: 16)]
    }
    
    func staggerAgain() {
        items += (0...5).map({ _ in
            StaggerItem()
        })
    }
    
    var body: some View {
        ScrollView {
            VStack {
                bannder
                    .stagger(
                        .slide.combined(with: .opacity),
                        priority: -1
                    )
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) {
                        $0.stagger(.scale)
                    }
                }
            }
            .padding(20)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: staggerAgain) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.largeTitle)
                    .frame(width: 60, height: 60)
                    .background {
                        Circle()
                            .fill(Color(uiColor: .systemGray6))
                    }
            }
            .buttonStyle(.plain)
            .padding()
        }
        .modifier(StaggerItem.Parent())
    }
}

#Preview {
    StaggeredRevisited()
}
