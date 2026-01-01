//
//  iPhoneSimulatorChrome.swift
//  SwiftTalk
//
//  Created by D CHENG on 1/1/26.
//

import SwiftUI

struct Device {
    let size: CGSize
    
    static let iPhone13 = Device(size: .init(width: 390, height: 844))
}

struct PhoneModifier: ViewModifier {
    let device: Device
    var scheme: ColorScheme = .light
    
    var deviceShape: some Shape {
        RoundedRectangle(cornerRadius: 40, style: .continuous)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: device.size.width, height: device.size.height)
            .background(.background)
            .clipShape(deviceShape)
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
    }
}

#Preview {
    iPhoneSimulatorChrome()
}
