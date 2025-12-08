//
//  Expense.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 04.12.2025.
//

import Foundation
import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case food = "food"
    case veterinaryCare = "veterinary_care"
    case toys = "toys"
    case grooming = "grooming"
    case accessories = "accessories"
    case vitaminsAndSupplements = "vitamins_and_supplements"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .food:
            return "Food"
        case .veterinaryCare:
            return "Veterinary care"
        case .toys:
            return "Toys"
        case .grooming:
            return "Grooming"
        case .accessories:
            return "Accessories"
        case .vitaminsAndSupplements:
            return "Vitamins and supplements"
        case .other:
            return "Other"
        }
    }
    
    var color: Color {
        switch self {
        case .food:
            return .categoryFood
        case .veterinaryCare:
            return .categoryVeterinaryCare
        case .toys:
            return .categoryToys
        case .grooming:
            return .categoryGrooming
        case .accessories:
            return .categoryAccessories
        case .vitaminsAndSupplements:
            return .categoryVitaminsAndSupplements
        case .other:
            return .categoryOther
        }
    }
}

struct PetExpense: Identifiable, Codable, Hashable {
    let id: UUID
    let petId: UUID
    let category: ExpenseCategory
    let amount: Decimal
    let date: Date
    let note: String?
    
    init(
        id: UUID = UUID(),
        petId: UUID,
        category: ExpenseCategory,
        amount: Decimal,
        date: Date,
        note: String? = nil
    ) {
        self.id = id
        self.petId = petId
        self.category = category
        self.amount = amount
        self.date = date
        self.note = note
    }
}

struct SpendingLimit: Identifiable, Codable, Hashable {
    let id: UUID
    let petId: UUID
    let category: ExpenseCategory?
    let month: MonthPeriod
    let amount: Decimal
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        petId: UUID,
        category: ExpenseCategory? = nil,
        month: MonthPeriod,
        amount: Decimal,
        isActive: Bool = true
    ) {
        self.id = id
        self.petId = petId
        self.category = category
        self.month = month
        self.amount = amount
        self.isActive = isActive
    }
}

struct LimitUsage: Identifiable, Hashable {
    var id: UUID { limit.id }
    
    let limit: SpendingLimit
    let spent: Decimal
    
    var fractionUsed: Double {
        let total = (limit.amount as NSDecimalNumber).doubleValue
        let used = (spent as NSDecimalNumber).doubleValue
        if total <= 0 {
            return 1.0
        } else {
            return used / total
        }
    }
    
    var percentUsed: Double {
        fractionUsed * 100.0
    }
    
    var isExceeded: Bool {
        spent > limit.amount
    }
    
    var isWarning: Bool {
        fractionUsed >= 0.9 && !isExceeded
    }
}

extension Array where Element == PetExpense {
    func expenses(for petId: UUID) -> [PetExpense] {
        self.filter { $0.petId == petId }
    }
    
    func expenses(
        for petId: UUID,
        in month: MonthPeriod,
        calendar: Calendar = .current
    ) -> [PetExpense] {
        let petExpenses = expenses(for: petId)
        return petExpenses.filter { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            let year = components.year ?? 0
            let monthValue = components.month ?? 0
            return year == month.year && monthValue == month.month
        }
    }
    
    func totalAmount(
        for petId: UUID,
        in month: MonthPeriod,
        category: ExpenseCategory? = nil,
        calendar: Calendar = .current
    ) -> Decimal {
        let monthlyExpenses = expenses(for: petId, in: month, calendar: calendar)
        let filtered = monthlyExpenses.filter { expense in
            if let category = category {
                return expense.category == category
            } else {
                return true
            }
        }
        return filtered.reduce(Decimal.zero) { partial, expense in
            partial + expense.amount
        }
    }
    
    func categoryBreakdown(
        for petId: UUID,
        in month: MonthPeriod,
        calendar: Calendar = .current
    ) -> [ExpenseCategory: Decimal] {
        let monthlyExpenses = expenses(for: petId, in: month, calendar: calendar)
        var result: [ExpenseCategory: Decimal] = [:]
        for expense in monthlyExpenses {
            let current = result[expense.category] ?? Decimal.zero
            result[expense.category] = current + expense.amount
        }
        return result
    }
    
    func usage(for limit: SpendingLimit, calendar: Calendar = .current) -> LimitUsage {
        let totalForPetAndMonth = totalAmount(
            for: limit.petId,
            in: limit.month,
            category: limit.category,
            calendar: calendar
        )
        return LimitUsage(
            limit: limit,
            spent: totalForPetAndMonth
        )
    }
    
    func usages(
        for limits: [SpendingLimit],
        calendar: Calendar = .current
    ) -> [LimitUsage] {
        limits.map { limit in
            usage(for: limit, calendar: calendar)
        }
    }
}
