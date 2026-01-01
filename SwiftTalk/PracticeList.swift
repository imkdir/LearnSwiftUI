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
    case slides
    case checkmarks
    case scalable
    case magnification
    case matchedGeometryEffect
    case largeScrollingGraph
    case treeDiagram
    case asyncTimeline
    case photoGrid
    case layoutInspector
    case customComponent
    case staggeredAnimations
    case staggeredFigures
    
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
        case .slides:
            "Slides"
        case .checkmarks:
            "Checkmarks"
        case .scalable:
            "Scalable"
        case .magnification:
            "Magnification"
        case .matchedGeometryEffect:
            "Matched Geometry Effect"
        case .largeScrollingGraph:
            "Large Scrolling Graph"
        case .treeDiagram:
            "Tree Diagram"
        case .asyncTimeline:
            "Async Timeline"
        case .photoGrid:
            "Photo Grid"
        case .layoutInspector:
            "Layout Inspector"
        case .customComponent:
            "Custom Component"
        case .staggeredAnimations:
            "Staggered Animations"
        case .staggeredFigures:
            "Staggered Figures"
        }
    }
}

struct PracticeList: View {
    
    var body: some View {
        NavigationStack {
            List(Practice.allCases.reversed()) {
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
                case .slides:
                    Slides()
                case .checkmarks:
                    CheckmarkPreviews()
                case .scalable:
                    ScalablePlayground()
                case .magnification:
                    MagnificationPlayground()
                case .matchedGeometryEffect:
                    MatchedGeometryEffectDemo()
                case .largeScrollingGraph:
                    LargeScrollingGraph()
                case .treeDiagram:
                    TreeDiagramDemo()
                case .asyncTimeline:
                    StreamMap()
                case .photoGrid:
                    PhotoGrid()
                case .layoutInspector:
                    LayoutInspector()
                case .customComponent:
                    CoffeeCart()
                case .staggeredAnimations:
                    StaggeredAnimations()
                case .staggeredFigures:
                    StaggeredRevisited()
                }
            }
        }
    }
}
