import SwiftUI

struct PetCardView: View {
    @EnvironmentObject private var store: PetStore
    
    let pet: Pet
    
    private var monthName: String {
        let month = store.selectedMonth
        return month.monthName()
    }
    
    private var totalForMonth: Decimal {
        store.totalForSelectedMonth(for: pet)
    }
    
    private var mainLimitUsage: LimitUsage? {
        let usages = store.limitUsages(for: pet)
        if let food = usages.first(where: { $0.limit.category == .food }) {
            return food
        }
        return usages.first
    }
    
    private var limitTitle: String {
        if let category = mainLimitUsage?.limit.category {
            switch category {
            case .food:
                return "Food limit"
            case .veterinaryCare:
                return "Veterinary limit"
            case .toys:
                return "Toys limit"
            case .grooming:
                return "Grooming limit"
            case .accessories:
                return "Accessories limit"
            case .vitaminsAndSupplements:
                return "Vitamins limit"
            case .other:
                return "Other limit"
            }
        } else {
            return "Total limit"
        }
    }
    
    private var limitAmountText: String {
        guard let limit = mainLimitUsage?.limit else { return "$0" }
        return formatCurrency(limit.amount)
    }
    
    private var limitPercentText: String {
        guard let usage = mainLimitUsage else { return "0%" }
        let value = Int(round(usage.percentUsed))
        return "\(value)%"
    }
    
    private var limitFraction: Double {
        guard let usage = mainLimitUsage else { return 0 }
        return min(max(usage.fractionUsed, 0), 1.5)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            avatarView
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(pet.name)
                        .appFont(.arialBold, size: 24)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Text(pet.kind.displayName)
                        .appFont(.arialRegular, size: 16)
                        .foregroundColor(.white)
                        .italic()
                }
                
                HStack(spacing: 4) {
                    Text("For \(monthName):")
                        .appFont(.arialRegular, size: 18)
                        .foregroundColor(.white)
                    
                    Text(formatCurrency(totalForMonth))
                        .appFont(.arialBold, size: 18)
                        .foregroundColor(.categoryVitaminsAndSupplements)
                }
                
                HStack(spacing: 4) {
                    Text("\(limitTitle):")
                        .appFont(.arialRegular, size: 18)
                        .foregroundColor(.white)
                    
                    Text(limitAmountText)
                        .appFont(.arialRegular, size: 18)
                        .foregroundColor(.white)
                    
                    Text("(\(limitPercentText))")
                        .appFont(.arialBold, size: 18)
                        .foregroundColor(.categoryVitaminsAndSupplements)
                }
                
                LimitProgressBar(fraction: limitFraction)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appPrimaryBlue, lineWidth: 2)
        )
        .clipped()
        .compositingGroup()
    }
    
    private var avatarView: some View {
        Group {
            if let data = pet.photoData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPrimaryBlue, lineWidth: 1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appPrimaryBlue, lineWidth: 1)
                        )
                    
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.appAccentYellow)
                        .padding(24)
                }
                .frame(width: 110, height: 110)
            }
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let number = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: number) ?? "$0"
    }
}

struct LimitProgressBar: View {
    let fraction: Double
    
    private var clamped: Double {
        min(max(fraction, 0), 1.5)
    }
    
    private var fillColor: Color {
        if clamped >= 1.0 {
            return .red
        } else if clamped >= 0.9 {
            return .appAccentYellow
        } else {
            return .categoryVitaminsAndSupplements
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let displayed = min(max(fraction, 0), 1)
            let filledWidth = geo.size.width * displayed
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: geo.size.height / 2)
                    .fill(Color.black.opacity(0.5))
                
                RoundedRectangle(cornerRadius: geo.size.height / 2)
                    .fill(fillColor)
                    .frame(width: filledWidth)
            }
        }
        .frame(height: 10)
    }
}

extension MonthPeriod {
    func monthName(locale: Locale = Locale(identifier: "en_US")) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date)
    }
}

#Preview {
    let store = PetStore.preview
    return ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            PetCardView(pet: store.pets[0])
                .environmentObject(store)
                .padding()
            Spacer()
        }
    }
}
