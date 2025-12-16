//
//  Stopwatch.swift
//  SwiftTalk
//
//  Created by 程東 on 12/16/25.
//

import SwiftUI

struct Stopwatch: View {
    var body: some View {
        HStack {
            Button {
                
            } label: {
                Text("Stop")
            }
            .foregroundStyle(.red)
            Spacer()
            
            Button {
                
            } label: {
                Text("Start")
            }
            .foregroundStyle(.green)
        }
        .buttonStyle(CircleStyle())
        .padding()
    }
}

struct CircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .fill()
            configuration.isPressed
                ? Circle().fill(Color(uiColor: .init(white: 1, alpha: 0.3)))
                : nil
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(.white)
                .padding(4)
            configuration.label
                .foregroundStyle(.white)
        }
        .frame(width: 75, height: 75)
    }
}
