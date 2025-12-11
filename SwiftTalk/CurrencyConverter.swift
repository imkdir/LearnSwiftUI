//
//  CurrencyConverter.swift
//  SwiftTalk
//
//  Created by 程東 on 12/11/25.
//

import SwiftUI

struct CurrencyConverter {
    @State private var input: String = "42"
    @State private var currency: String = "USD"
    
    private var rate: Double {
        rates[currency, default: 0.0]
    }
    
    private var output: String {
        Double(input).flatMap({
            formatter.string(from: NSNumber(value: $0 * rate))
        }) ?? "NaN"
    }
    
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = ""
        return f
    }()
    
    private let rates: [String: Double] = [
        "USD": 1.17,
        "GBP": 0.87,
        "CNY": 8.26
    ]
}

extension CurrencyConverter: View {
    var body: some View {
        HStack {
            TextField("input", text: $input)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            Text("EUR")
            Text("=")
            Text(output).bold()
            Picker("picker", selection: $currency) {
                ForEach(rates.keys.sorted(), id: \.self, content: Text.init)
            }.frame(width: 100)
        }
    }
}
