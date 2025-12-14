//
//  InfiniteShape.swift
//  SwiftTalk
//
//  Created by 程東 on 12/14/25.
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
    
    func pointAndAngle(at position: CGFloat) -> (CGPoint, Angle) {
        let res = point(at: position)
        let ref = point(at: (position + 0.01).truncatingRemainder(dividingBy: 1))
        let angle = Angle(radians: .init(atan2(ref.y-res.y, ref.x-res.x)))
        return (res, angle)
    }
}

struct TravlerEffect<Guide: Shape>: GeometryEffect {
    let guide: Guide
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let guidePath = guide.path(in: .init(origin: .zero, size: size))
        let (point, angle) = guidePath.pointAndAngle(at: progress)
        let transform = CGAffineTransform(
            translationX: point.x,
            y: point.y
        ).rotated(
            by: .init(angle.radians) + .pi/2
        )
        
        return ProjectionTransform(transform)
    }
}

struct Trail<P: Shape>: Shape {
    
    let content: P
    var strokeStyle: StrokeStyle = .init()
    
    var offset: CGFloat
    var length: CGFloat = 0.2

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let path = content.path(in: rect)
        let trimFrom = offset - length
        
        var result = Path()
        
        if trimFrom < 0 {
            let wrapAroundTrail = path
                .trimmedPath(from: trimFrom + 1, to: 1)
            result.addPath(wrapAroundTrail)
        }
        
        let mainTrail = path
            .trimmedPath(from: max(0, trimFrom), to: offset)
        result.addPath(mainTrail)
        
        return result.strokedPath(strokeStyle)
    }
}
