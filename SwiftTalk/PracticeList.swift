//
//  PracticeList.swift
//  SwiftTalk
//
//  Created by 程東 on 12/14/25.
//

import SwiftUI

enum Practice: String, Identifiable, CaseIterable {
    case currencyConverter
    case loadingIndicator
    case flowLayoutPlayground
    case shakeIt
    case animationCurves
    case shoppingCart
    case stopwatchPage
    case map
    
    var id: Self {
        self
    }
    
    var title: String {
        switch self {
        case .currencyConverter:
            "Currency Converter"
        case .loadingIndicator:
            "Loading Indicator"
        case .flowLayoutPlayground:
            "FlowLayout Playground"
        case .shakeIt:
            "Shake It!"
        case .animationCurves:
            "Animation Curves"
        case .shoppingCart:
            "Shopping Cart"
        case .stopwatchPage:
            "Stopwatch Page"
        case .map:
            "Map"
        }
    }
}

struct PracticeList: View {
    
    var body: some View {
        NavigationStack {
            List(Practice.allCases) {
                NavigationLink($0.title, value: $0)
            }
            .navigationTitle("Practices")
            .navigationDestination(for: Practice.self) {
                switch $0 {
                case .currencyConverter:
                    CurrencyConverter()
                case .loadingIndicator:
                    LoadingIndicator()
                case .flowLayoutPlayground:
                    FlowLayoutPlayground()
                case .shakeIt:
                    ShakeIt()
                case .animationCurves:
                    AnimationCurves()
                case .shoppingCart:
                    ShoppingCart()
                case .stopwatchPage:
                    StopwatchPage()
                case .map:
                    MapView()
                }
            }
        }
    }
}
