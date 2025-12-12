//
//  CurrencyConverter.swift
//  SwiftTalk
//
//  Created by 程東 on 12/11/25.
//

import SwiftUI
import Observation
import TinyNetworking

struct FixerData: Codable {
    var rates: [String: Double]
}

private let baseUrl = "http://data.fixer.io/api"
private let apiKey = "6c03d31807226b92f10012fe61ee5b2e"
private let latest = Endpoint<FixerData>(
    json: .get,
    url: URL(string: "\(baseUrl)/latest?access_key=\(apiKey)")!
)



struct CurrencyConverter {
    @State private var input: String = "42"
    @State private var currency: String = "USD"
    
    private let resource = Resource(endpoint: latest)
    
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
    
    private var rates: [String: Double] {
        resource.value?.rates ?? ["USD": 1.17]
    }
}

extension CurrencyConverter: View {
    var body: some View {
        VStack {
            HStack {
                TextField("input", text: $input)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .fixedSize()
                Text("EUR")
                Text("=")
                Text(output)
                    .bold()
                    .multilineTextAlignment(.trailing)
                Picker("picker", selection: $currency) {
                    ForEach(rates.keys.sorted(), id: \.self, content: Text.init)
                }
                .fixedSize()
            }
            Button("Refresh") {
                resource.reload()
            }
            .buttonStyle(.glassProminent)
        }
    }
}

#Preview {
    CurrencyConverter()
}
