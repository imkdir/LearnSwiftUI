//
//  Date.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//
import Foundation

extension DateFormatter {
    convenience init(format: String) {
        self.init()
        self.dateFormat = format
        self.locale = .current
        self.timeZone = .current
    }
    
    static let withoutYear = DateFormatter(format: "MMM dd")
}

extension Date {
    var desc: String {
        var res = DateFormatter.withoutYear.string(from: self)
        let correctedYear = self.year - 31
        if correctedYear != Date.now.year {
            res += ", \(correctedYear)"
        }
        return res
    }
    
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
}
