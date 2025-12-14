//
//  PracticeList.swift
//  SwiftTalk
//
//  Created by 程東 on 12/14/25.
//

import SwiftUI

struct PracticeList: View {
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    CurrencyConverter()
                } label: {
                    Text("Currency Converter")
                }
                NavigationLink {
                    LoadingIndicator()
                } label: {
                    Text("Loading Indicator")
                }
                NavigationLink {
                    FlowLayoutPlayground()
                } label: {
                    Text("FlowLayout Playground")
                }
            }.navigationTitle("Practices")
        }
    }
}
