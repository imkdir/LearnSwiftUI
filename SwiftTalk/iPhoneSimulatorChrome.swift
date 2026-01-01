//
//  iPhoneSimulatorChrome.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/1/26.
//

import SwiftUI

struct Device {
    let size: CGSize
    let bezelWidth: CGFloat = 10
    let topSafeAreaHeight: CGFloat = 47
    let bottomSafeAreaHeight: CGFloat = 34
    
    static let iPhone13 = Device(size: .init(width: 390, height: 844))
}

struct PhoneModifier: ViewModifier {
    let device: Device
    var scheme: ColorScheme = .light
    
    var deviceShape: some Shape {
        RoundedRectangle(cornerRadius: 40, style: .continuous)
    }
    
    var topBar: some View {
        HStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: Date.FormatStyle(date: .none, time: .shortened))
                    .fontWeight(.medium)
                    .padding(.leading, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Capsule()
                .padding(.vertical, 12)
                .frame(width: 120)
            HStack {
                Image(systemName: "wifi")
                Image(systemName: "battery.75")
            }
            .padding(.trailing, 24)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    var homeIndicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .frame(width: 160, height: 5)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                topBar
                    .frame(height: device.topSafeAreaHeight)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                homeIndicator
                    .frame(height: device.bottomSafeAreaHeight)
            }
            .frame(width: device.size.width, height: device.size.height)
            .background(.background)
            .clipShape(deviceShape)
            .overlay {
                deviceShape
                    .stroke(.black, lineWidth: device.bezelWidth)
            }
            .padding(device.bezelWidth)
            .colorScheme(scheme)
    }
}

struct iPhoneSimulatorChrome: View {
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
            Text("Hello, World!")
        }
        .modifier(PhoneModifier(device: .iPhone13))
        .padding()
        .background(.blue)
    }
}

#Preview {
    iPhoneSimulatorChrome()
}
