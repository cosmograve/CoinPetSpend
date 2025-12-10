import SwiftUI
import Combine
import Foundation

final class PetStore: ObservableObject {
    @Published var pets: [Pet] {
        didSet { persistState() }
    }
    
    @Published var expenses: [PetExpense] {
        didSet { persistState() }
    }
    
    @Published var limits: [SpendingLimit] {
        didSet { persistState() }
    }
    
    @Published var selectedMonth: MonthPeriod {
        didSet { persistState() }
    }
    
    private let userDefaults: UserDefaults
    private let stateKey = "PetStore.state"
    
    private struct State: Codable {
        var pets: [Pet]
        var expenses: [PetExpense]
        var limits: [SpendingLimit]
        var selectedMonth: MonthPeriod
    }
    
    init(
        pets: [Pet] = [],
        expenses: [PetExpense] = [],
        limits: [SpendingLimit] = [],
        selectedMonth: MonthPeriod = .current(),
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        self.pets = pets
        self.expenses = expenses
        self.limits = limits
        self.selectedMonth = selectedMonth
        loadState()
    }
    
    func addPet(
        name: String,
        kind: PetKind,
        birthDate: Date? = nil,
        photoData: Data? = nil
    ) {
        let pet = Pet(
            name: name,
            kind: kind,
            birthDate: birthDate,
            photoData: photoData
        )
        pets.append(pet)
    }
    
    func updatePet(
        _ pet: Pet,
        name: String? = nil,
        kind: PetKind? = nil,
        birthDate: Date?? = nil,
        photoData: Data?? = nil
    ) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        var updated = pets[index]
        
        if let name = name {
            updated.name = name
        }
        if let kind = kind {
            updated.kind = kind
        }
        if let birthDateValue = birthDate {
            updated.birthDate = birthDateValue
        }
        if let photoDataValue = photoData {
            updated.photoData = photoDataValue
        }
        
        pets[index] = updated
    }
    
    func deletePet(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        expenses.removeAll { $0.petId == pet.id }
        limits.removeAll { $0.petId == pet.id }
    }
    
    func addExpense(
        for pet: Pet,
        category: ExpenseCategory,
        amount: Decimal,
        date: Date = Date(),
        note: String? = nil
    ) {
        let expense = PetExpense(
            petId: pet.id,
            category: category,
            amount: amount,
            date: date,
            note: note
        )
        expenses.append(expense)
    }
    
    func addLimit(
        for pet: Pet,
        category: ExpenseCategory? = nil,
        month: MonthPeriod,
        amount: Decimal,
        isActive: Bool = true
    ) {
        let limit = SpendingLimit(
            petId: pet.id,
            category: category,
            month: month,
            amount: amount,
            isActive: isActive
        )
        limits.append(limit)
    }
    
    func updateLimit(
        _ limit: SpendingLimit,
        for pet: Pet,
        category: ExpenseCategory?,
        month: MonthPeriod,
        amount: Decimal
    ) {
        guard let index = limits.firstIndex(where: { $0.id == limit.id }) else {
            return
        }
        
        let current = limits[index]
        
        let updated = SpendingLimit(
            id: current.id,
            petId: pet.id,
            category: category,
            month: month,
            amount: amount,
            isActive: current.isActive
        )
        
        limits[index] = updated
    }
    
    func expenses(for pet: Pet) -> [PetExpense] {
        expenses.expenses(for: pet.id)
    }
    
    func expensesForSelectedMonth(for pet: Pet, calendar: Calendar = .current) -> [PetExpense] {
        expenses.expenses(for: pet.id, in: selectedMonth, calendar: calendar)
    }
    
    func totalForSelectedMonth(for pet: Pet, calendar: Calendar = .current) -> Decimal {
        expenses.totalAmount(for: pet.id, in: selectedMonth, calendar: calendar)
    }
    
    func limits(for pet: Pet) -> [SpendingLimit] {
        limits.filter { $0.petId == pet.id && $0.isActive && $0.month == selectedMonth }
    }
    
    func limitUsages(for pet: Pet, calendar: Calendar = .current) -> [LimitUsage] {
        let petLimits = limits(for: pet)
        return expenses.usages(for: petLimits, calendar: calendar)
    }
    
    private func loadState() {
        guard let data = userDefaults.data(forKey: stateKey) else { return }
        let decoder = JSONDecoder()
        guard let state = try? decoder.decode(State.self, from: data) else { return }
        pets = state.pets
        expenses = state.expenses
        limits = state.limits
        selectedMonth = state.selectedMonth
    }
    
    private func persistState() {
        let state = State(
            pets: pets,
            expenses: expenses,
            limits: limits,
            selectedMonth: selectedMonth
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(state) else { return }
        userDefaults.set(data, forKey: stateKey)
    }
}

extension PetStore {
    static var preview: PetStore {
        let month = MonthPeriod.current()
        
        let pet1 = Pet(
            name: "Felix",
            kind: .cat
        )
        
        let pet2 = Pet(
            name: "Rex",
            kind: .dog
        )
        
        let expenses: [PetExpense] = [
            PetExpense(
                petId: pet1.id,
                category: .food,
                amount: 84,
                date: Date(),
                note: "Premium food"
            ),
            PetExpense(
                petId: pet1.id,
                category: .veterinaryCare,
                amount: 90,
                date: Date(),
                note: "Vaccination"
            ),
            PetExpense(
                petId: pet2.id,
                category: .toys,
                amount: 30,
                date: Date(),
                note: "New ball"
            )
        ]
        
        let limits: [SpendingLimit] = [
            SpendingLimit(
                petId: pet1.id,
                category: .food,
                month: month,
                amount: 120
            ),
            SpendingLimit(
                petId: pet1.id,
                category: .veterinaryCare,
                month: month,
                amount: 80
            )
        ]
        
        return PetStore(
            pets: [pet1, pet2, pet1, pet2, pet1, pet2, pet1, pet2],
            expenses: expenses,
            limits: limits,
            selectedMonth: month
        )
    }
}
