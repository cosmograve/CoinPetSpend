//
//  Period.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 04.12.2025.
//

import Foundation

struct MonthPeriod: Codable, Hashable {
    let year: Int
    let month: Int
    
    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    
    static func current(using calendar: Calendar = .current) -> MonthPeriod {
        let components = calendar.dateComponents([.year, .month], from: Date())
        let year = components.year ?? 2000
        let month = components.month ?? 1
        return MonthPeriod(year: year, month: month)
    }
    
    func addingMonths(_ offset: Int, calendar: Calendar = .current) -> MonthPeriod {
        var components = DateComponents()
        components.year = year
        components.month = month
        let baseDate = calendar.date(from: components) ?? Date()
        let newDate = calendar.date(byAdding: .month, value: offset, to: baseDate) ?? baseDate
        let newComponents = calendar.dateComponents([.year, .month], from: newDate)
        let newYear = newComponents.year ?? year
        let newMonth = newComponents.month ?? month
        return MonthPeriod(year: newYear, month: newMonth)
    }
    
    func formatted(
        using calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        let date = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
}
