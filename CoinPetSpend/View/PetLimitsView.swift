import SwiftUI

struct PetLimitsView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    @State private var showAddLimit = false
    
    private let buttonHorizontalPadding: CGFloat = 69
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60
    
    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }
    
    private var petLimits: [SpendingLimit] {
        store.limits(for: pet)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppNavigationBar(
                    title: "LIMITS",
                    onBack: { dismiss() },
                    onMore: nil
                )
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        
                        if petLimits.isEmpty {
                            emptyState
                        } else {
                            limitsList
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, contentBottomPadding)
                }
            }
        }
        .overlay(alignment: .bottom) {
            PrimaryActionButton(title: "+ New Limit") {
                showAddLimit = true
            }
            .frame(height: buttonHeight)
            .padding(.horizontal, buttonHorizontalPadding)
            .padding(.bottom, buttonOffsetFromBottom)
        }
        .navigationDestination(isPresented: $showAddLimit) {
            AddLimitView(
                pet: pet,
                limitToEdit: nil
            )
            .environmentObject(store)
            .navigationBarBackButtonHidden()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            headerAvatar
                .frame(width: 120, height: 120)
            
            Text(pet.name)
                .appFont(.arialBold, size: 28)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var headerAvatar: some View {
        Group {
            if let data = pet.photoData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.appPrimaryBlue, lineWidth: 2)
                        )
                    
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.appAccentYellow)
                        .padding(28)
                }
                .frame(width: 120, height: 120)
            }
        }
    }
    
    private var emptyState: some View {
        VStack {
            Spacer(minLength: 40)
            
            Text("NO LIMITS SET FOR THIS PET")
                .appFont(.arialBold, size: 24)
                .foregroundColor(.appAccentYellow)
                .multilineTextAlignment(.center)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var limitsList: some View {
        VStack(spacing: 16) {
            ForEach(petLimits) { limit in
                NavigationLink {
                    AddLimitView(
                        pet: pet,
                        limitToEdit: limit
                    )
                    .environmentObject(store)
                    .navigationBarBackButtonHidden()
                } label: {
                    PetLimitCardView(limit: limit)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let store = PetStore.preview
    return NavigationStack {
        PetLimitsView(pet: store.pets[0])
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}

struct PetLimitCardView: View {
    let limit: SpendingLimit
    
    private var title: String {
        if let category = limit.category {
            switch category {
            case .food: return "Food"
            case .veterinaryCare: return "Veterinary care"
            case .toys: return "Toys"
            case .grooming: return "Grooming"
            case .accessories: return "Accessories"
            case .vitaminsAndSupplements: return "Vitamins and supplements"
            case .other: return "Other"
            }
        } else {
            return "Total"
        }
    }
    
    private var monthText: String {
        let monthName = limit.month.monthName(locale: Locale(identifier: "en_US"))
        return "Month: \(monthName)"
    }
    
    private var amountText: String {
        formatCurrency(limit.amount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .appFont(.arialBold, size: 20)
                    .foregroundColor(.appAccentYellow)
                
                Spacer()
                
                Text(amountText)
                    .appFont(.arialRegular, size: 20)
                    .foregroundColor(.categoryVitaminsAndSupplements)
            }
            
            Text(monthText)
                .appFont(.arialRegular, size: 16)
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appPrimaryBlue, lineWidth: 2)
        )
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let number = value as NSDecimalNumber
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f.string(from: number) ?? "$0"
    }
}
