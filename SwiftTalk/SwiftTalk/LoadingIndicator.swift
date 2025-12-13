//
//  LoadingIndicator.swift
//  SwiftTalk
//
//  Created by 程東 on 12/13/25.
//

import SwiftUI

struct InfiniteShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let begin = CGPoint(x: 0.75, y: 0)
            p.move(to: begin)
            p.addQuadCurve(to: .init(x: 1, y: 0.5), control: .init(x: 1, y: 0))
            p.addQuadCurve(to: .init(x: 0.75, y: 1), control: .init(x: 1, y: 1))
            p.addCurve(to: .init(x: 0.25, y: 0), control1: .init(x: 0.5, y: 1), control2: .init(x: 0.5, y: 0))
            p.addQuadCurve(to: .init(x: 0, y: 0.5), control: .init(x: 0, y: 0))
            p.addQuadCurve(to: .init(x: 0.25, y: 1), control: .init(x: 0, y: 1))
            p.addCurve(to: begin, control1: .init(x: 0.5, y: 1), control2: .init(x: 0.5, y: 0))
        }.applying(.init(scaleX: rect.width, y: rect.height))
    }
}

extension Path {
    func point(at position: CGFloat) -> CGPoint {
        assert(0 ... 1 ~= position)
        let path = position > 0 ? trimmedPath(from: 0, to: position) : self
        return path.cgPath.currentPoint
    }
}

struct TravelerOnPath<Guide: Shape, Traveler: Shape>: Shape {
    
    let guide: Guide
    var traveler: Traveler
    
    var travelOffset: CGFloat
    var trailLength: CGFloat = 0.2

    var animatableData: AnimatablePair<CGFloat, Traveler.AnimatableData> {
        get {
            AnimatablePair(travelOffset, traveler.animatableData)
        }
        set {
            travelOffset = newValue.first
            traveler.animatableData = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let guidePath = guide.path(in: rect)
        let travelerPoint = guidePath.point(at: travelOffset)
        let travelerPath = traveler.path(in: rect)
        let travelerSize = travelerPath.boundingRect.size
        
        let centeredTraveler = travelerPath
            .offsetBy(
                dx: travelerPoint.x - travelerSize.width / 2,
                dy: travelerPoint.y - travelerSize.height / 2
            )
        
        var result = Path()
        let trimFrom = travelOffset - trailLength
        
        if trimFrom < 0 {
            let wrapAroundTrail = guidePath
                .trimmedPath(from: trimFrom + 1, to: 1)
                .strokedPath(.init())
            result.addPath(wrapAroundTrail)
        }
        
        let mainTrail = guidePath
            .trimmedPath(from: max(0, trimFrom), to: travelOffset)
            .strokedPath(.init())
        result.addPath(mainTrail)
        
        result.addPath(centeredTraveler)
        
        return result
    }
}

struct LoadingIndicator: View {
    
    let duration: Double = 1.5
    
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ZStack {
            InfiniteShape()
                .stroke(Color.secondary)
            TravelerOnPath(
                guide: InfiniteShape(),
                traveler: Circle().size(width: 30, height: 30),
                travelOffset: progress
            )
            .foregroundStyle(Color.primary)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: false),
                value: progress
            )
        }
        .aspectRatio(16/9, contentMode: .fit)
        .padding(20)
        .onAppear {
            self.progress = 1
        }
    }
}
