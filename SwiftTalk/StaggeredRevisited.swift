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

struct StaggerItem: Identifiable, View {
    let id = UUID()
    let icon = icons.randomElement() ?? "figure.walk"
    let color = colors.randomElement() ?? .black
    
    @State private var displayIconName: Bool = false
    
    struct NamespacesPreference: PreferenceKey {
        static var defaultValue: [Namespace.ID] = []
        
        static func reduce(value: inout [Namespace.ID], nextValue: () -> [Namespace.ID]) {
            value += nextValue()
        }
    }
    
    struct Parent: ViewModifier {
        @State private var viewIDs: [Namespace.ID] = []
        @State private var viewedIDs: Set<Namespace.ID> = []
        
        var delays: [Namespace.ID: Double] {
            Dictionary(uniqueKeysWithValues: viewIDs.enumerated().map({
                ($1, Double($0) * 0.2)
            }))
        }
        
        func body(content: Content) -> some View {
            content
                .environment(\.colorfulDelays, delays)
                .onPreferenceChange(NamespacesPreference.self) {
                    self.viewIDs = $0.filter({ !viewedIDs.contains($0) })
                    self.viewedIDs.formUnion(self.viewIDs)
                }
        }
    }
    
    struct Child<T: Transition>: ViewModifier {
        let transition: T
        @Namespace private var namespace
        @Environment(\.colorfulDelays) private var delays
        @State private var visible = false
        
        var delay: Double? {
            delays[namespace]
        }
        
        func body(content: Content) -> some View {
            transition
                .apply(content: content, phase: visible ? .identity : .willAppear)
                .preference(key: NamespacesPreference.self, value: [namespace])
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
    func stagger<T: Transition>(_ transition: T) -> some View {
        modifier(StaggerItem.Child(transition: transition))
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
                    .stagger(.slide.combined(with: .opacity))
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
