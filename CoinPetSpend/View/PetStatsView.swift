import SwiftUI

enum CompareCategoryOption: Identifiable, Equatable {
    case perMonth
    case category(ExpenseCategory)
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .perMonth:
            return "Per month"
        case .category(let cat):
            return cat.displayName
        }
    }
    
    static var allOptions: [CompareCategoryOption] {
        [.perMonth] + ExpenseCategory.allCases.map { .category($0) }
    }
}

struct PetStatsView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) var dismiss
    
    @State private var showMenu = false
    @State private var showEdit = false
    @State private var showDeleteConfirmation = false
    @State private var showLimitsSheet = false
    
    @State private var showCompareList = false
    @State private var compareWithPet: Pet?
    
    @State private var showCompareCategoryDropdown = false
    @State private var selectedCompareCategory: CompareCategoryOption = .perMonth

    let pet: Pet
    
    private let navBarHeight: CGFloat = 44
    
    @State private var showAddExpense = false

    private let buttonHorizontalPadding: CGFloat = 38
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60

    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }
    
    private var monthTitle: String {
        store.selectedMonth.title()
    }
    
    private var totalForMonth: Decimal {
        store.totalForSelectedMonth(for: pet)
    }
    
    private var totalLimitForMonth: Decimal? {
        let limits = store.limits(for: pet).filter { $0.category == nil }
        guard !limits.isEmpty else { return nil }
        return limits.reduce(0) { $0 + $1.amount }
    }
    
    private var exceedInfo: (spent: Decimal, limit: Decimal, percent: Int)? {
        guard let limit = totalLimitForMonth, limit > 0 else { return nil }
        guard totalForMonth > limit else { return nil }
        let spentNumber = totalForMonth as NSDecimalNumber
        let limitNumber = limit as NSDecimalNumber
        let value = spentNumber.doubleValue / limitNumber.doubleValue * 100
        return (totalForMonth, limit, Int(round(value)))
    }
    
    private var categoryShares: [CategoryShare] {
        let expenses = store.expensesForSelectedMonth(for: pet)
        guard !expenses.isEmpty else { return [] }
        
        var sums: [ExpenseCategory: Decimal] = [:]
        for expense in expenses {
            sums[expense.category, default: 0] += expense.amount
        }
        
        let total = sums.values.reduce(Decimal.zero) { $0 + $1 }
        guard total > 0 else { return [] }
        let totalDouble = (total as NSDecimalNumber).doubleValue
        
        return ExpenseCategory.allCases.compactMap { category in
            guard let value = sums[category] else { return nil }
            let fraction = (value as NSDecimalNumber).doubleValue / totalDouble
            return CategoryShare(category: category, amount: value, fraction: fraction)
        }
        .sorted { $0.amount > $1.amount }
    }
    
    private var monthlyExpenses: [PetExpense] {
        store.expensesForSelectedMonth(for: pet)
            .sorted { $0.date > $1.date }
    }
    
    private var hasOtherPets: Bool {
        store.pets.contains { $0.id != pet.id }
    }
    
    private var otherPets: [Pet] {
        store.pets.filter { $0.id != pet.id }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppNavigationBar(
                    title: "PET STATS",
                    onBack: { dismiss() },
                    onMore: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showMenu.toggle()
                        }
                    }
                )
                
                if let exceedInfo {
                    VStack(spacing: 4) {
                        Text("Monthly limit exceeded!")
                            .appFont(.arialBold, size: 20)
                            .foregroundColor(.white)
                        
                        Text("Total spending: \(formatCurrency(exceedInfo.spent)) / \(formatCurrency(exceedInfo.limit)) (\(exceedInfo.percent)%)")
                            .appFont(.agText, size: 18)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.5, green: 0, blue: 0))
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        avatarSection
                        monthPickerSection
                        if !categoryShares.isEmpty {
                            MonthlyDonutCard(
                                total: totalForMonth,
                                shares: categoryShares,
                                formattedTotal: formatCurrency(totalForMonth)
                            )
                        }
                        LimitsCardView(
                            usages: store.limitUsages(for: pet),
                            onManageTap: { showLimitsSheet = true }
                        )
                        if !monthlyExpenses.isEmpty {
                            recentExpensesSection
                        }
                        
                        if let other = compareWithPet {
                            compareSection(with: other)
                        }
                        
                        if hasOtherPets {
                            PrimaryActionButton(title: "Compare Pets") {
                                showCompareList.toggle()
                            }
                            .padding(.horizontal, 50)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                    .padding(.bottom, contentBottomPadding)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if showMenu {
                VStack(spacing: 0) {
                    menuButton(
                        title: "Edit Pet",
                        iconName: "pencil",
                        isDestructive: false
                    ) {
                        showEdit = true
                        showMenu = false
                    }
                    
                    menuButton(
                        title: "Delete",
                        iconName: "trash",
                        isDestructive: true
                    ) {
                        showDeleteConfirmation = true
                        showMenu = false
                    }
                }
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 8,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .fill(Color.appPrimaryBlue)
                )
                .padding(.top, navBarHeight)
                .padding(.trailing, 0)
                .transition(
                    .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing))
                )
                .zIndex(100)
            }
        }
        .overlay {
            if showCompareList {
                compareOverlay
            }
        }
        .overlay(alignment: .bottom) {
            PrimaryActionButton(title: "Add expense") {
                showAddExpense = true
            }
            .frame(height: buttonHeight)
            .padding(.horizontal, 70)
            .padding(.bottom, buttonOffsetFromBottom)
        }
        .navigationDestination(isPresented: $showAddExpense) {
            AddExpenseView(pet: pet)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $showLimitsSheet) {
            PetLimitsView(pet: pet)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $showEdit) {
            AddPetView(petToEdit: pet)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
        .alert(
            "Delete Pet",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                store.deletePet(pet)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(pet.name)? This action cannot be undone.")
        }
        .onTapGesture {
            if showMenu {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showMenu = false
                }
            }
        }
    }
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            avatarView
                .frame(width: 100, height: 100)
            
            Text(pet.name)
                .appFont(.arialBold, size: 28)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var avatarView: some View {
        Group {
            if let data = pet.photoData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appPrimaryBlue, lineWidth: 2)
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.appAccentYellow)
                        .padding(24)
                }
            }
        }
    }
    
    private var monthPickerSection: some View {
        HStack(spacing: 16) {
            Button {
                store.selectedMonth = store.selectedMonth.adding(months: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appAccentYellow)
            }
            .buttonStyle(.plain)
            
            Text(monthTitle)
                .appFont(.arialBold, size: 28)
                .foregroundColor(.white)
            
            Button {
                store.selectedMonth = store.selectedMonth.adding(months: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appAccentYellow)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func menuButton(
        title: String,
        iconName: String,
        isDestructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let iconColor: Color = isDestructive ? .red : .appAccentYellow
        let textColor: Color = isDestructive ? .red : .white
        
        return Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .appFont(.agText, size: 16)
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 160, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent expenses")
                .appFont(.arialBold, size: 22)
                .foregroundColor(.white)
            
            ForEach(monthlyExpenses.prefix(5)) { expense in
                recentExpenseRow(expense)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func recentExpenseRow(_ expense: PetExpense) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dateText(expense.date)) - \(expense.category.displayName)")
                    .appFont(.agText, size: 18)
                    .foregroundColor(.white)
                
                if let note = expense.note,
                   !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("\"\(note)\"")
                        .appFont(.agText, size: 16)
                        .foregroundColor(.categoryVeterinaryCare)
                        .italic()
                }
            }
            
            Spacer()
            
            Text(formatCurrency(expense.amount))
                .appFont(.agText, size: 18)
                .foregroundColor(.categoryVitaminsAndSupplements)
        }
    }
    
    private var compareOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCompareList = false
                    }
                }
            
            VStack(spacing: 16) {
                ForEach(otherPets) { other in
                    Button {
                        compareWithPet = other
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCompareList = false
                        }
                    } label: {
                        HStack(spacing: 16) {
                            smallAvatar(for: other)
                                .frame(width: 72, height: 72)
                            
                            Text(other.name)
                                .appFont(.arialBold, size: 22)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .frame(maxWidth: 320, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
            )
            .padding(.horizontal, 24)
        }
        .zIndex(200)
    }
    
    private func smallAvatar(for pet: Pet) -> some View {
        Group {
            if let data = pet.photoData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appPrimaryBlue, lineWidth: 2)
                        )
                    
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundColor(.appAccentYellow)
                }
                .frame(width: 50, height: 50)
            }
        }
    }
    
    private func compareSection(with other: Pet) -> some View {
        let firstAmount = compareAmount(for: pet)
        let secondAmount = compareAmount(for: other)
        let maxAmount = max(firstAmount, secondAmount, 0)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Compare Pets")
                    .appFont(.arialBold, size: 22)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCompareCategoryDropdown.toggle()
                    }
                } label: {
                    Text("Select category")
                        .appFont(.agText, size: 18)
                        .foregroundColor(.appAccentYellow)
                }
                .buttonStyle(.plain)
            }
            
            compareRow(
                name: pet.name,
                amount: firstAmount,
                maxAmount: maxAmount,
                barColor: .categoryVitaminsAndSupplements
            )
            
            compareRow(
                name: other.name,
                amount: secondAmount,
                maxAmount: maxAmount,
                barColor: .categoryVeterinaryCare
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            if showCompareCategoryDropdown {
                compareCategoryDropdown
            }
        }
    }
    
    private var compareCategoryDropdown: some View {
        let width: CGFloat = 260
        let height: CGFloat = 280
        
        return VStack(alignment: .trailing, spacing: 18) {
            ForEach(CompareCategoryOption.allOptions) { option in
                Button {
                    selectedCompareCategory = option
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCompareCategoryDropdown = false
                    }
                } label: {
                    Text(option.title)
                        .appFont(.arialRegular, size: 14)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(
            CompareCategoryDropdownShape(cornerRadius: 24)
                .fill(Color.appBg)
                .overlay(
                    CompareCategoryDropdownShape(cornerRadius: 24)
                        .stroke(Color.appPrimaryBlue, lineWidth: 2)
                )
        )
        .frame(width: width, height: height, alignment: .bottomTrailing)
        .offset(y: -height - 8)
    }
        
    private func compareRow(
        name: String,
        amount: Decimal,
        maxAmount: Decimal,
        barColor: Color
    ) -> some View {
        let maxDouble = (maxAmount as NSDecimalNumber).doubleValue
        let valueDouble = (amount as NSDecimalNumber).doubleValue
        let fraction = maxDouble > 0 ? valueDouble / maxDouble : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .appFont(.arialBold, size: 20)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatCurrency(amount))
                    .appFont(.arialBold, size: 18)
                    .foregroundColor(barColor == .categoryVitaminsAndSupplements ? .categoryVitaminsAndSupplements : .categoryVeterinaryCare)
            }
            
            GeometryReader { geo in
                let width = geo.size.width
                let filledWidth = width * CGFloat(min(max(fraction, 0), 1))
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.12))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(barColor)
                        .frame(width: filledWidth)
                }
            }
            .frame(height: 12)
        }
    }
    
    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
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
    
    private func compareAmount(for pet: Pet) -> Decimal {
        let expenses = store.expensesForSelectedMonth(for: pet)
        
        switch selectedCompareCategory {
        case .perMonth:
            return expenses.reduce(Decimal.zero) { $0 + $1.amount }
        case .category(let category):
            let filtered = expenses.filter { $0.category == category }
            return filtered.reduce(Decimal.zero) { $0 + $1.amount }
        }
    }
}

struct CategoryShare: Identifiable {
    let category: ExpenseCategory
    let amount: Decimal
    let fraction: Double
    
    var id: ExpenseCategory { category }
    
    var percentText: String {
        let value = Int(round(fraction * 100))
        return "\(value)%"
    }
}

extension ExpenseCategory {
    var chartColor: Color {
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

struct DonutSlice: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let startAngle: Angle
    let endAngle: Angle
}

struct DonutSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

struct MonthlyDonutCard: View {
    let total: Decimal
    let shares: [CategoryShare]
    let formattedTotal: String
    
    private let ringWidth: CGFloat = 14
    
    private var slices: [DonutSlice] {
        var result: [DonutSlice] = []
        var current = -Double.pi / 2
        
        for share in shares {
            let delta = 2 * Double.pi * share.fraction
            let slice = DonutSlice(
                category: share.category,
                startAngle: Angle(radians: current),
                endAngle: Angle(radians: current + delta)
            )
            result.append(slice)
            current += delta
        }
        
        return result
    }
    
    var body: some View {
        HStack(spacing: 16) {
            donutView
                .frame(maxWidth: .infinity)
            legendView
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.appPrimaryBlue, lineWidth: 2)
                )
        )
    }
    
    private var donutView: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let chartSize = side
            let innerSize = chartSize - ringWidth * 2 - 8
            
            ZStack {
                ForEach(slices) { slice in
                    DonutSliceShape(
                        startAngle: slice.startAngle,
                        endAngle: slice.endAngle
                    )
                    .stroke(
                        slice.category.chartColor,
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt)
                    )
                    .frame(width: chartSize, height: chartSize)
                }
                
                VStack(spacing: 4) {
                    Text("Monthly total:")
                        .appFont(.agText, size: 14)
                        .foregroundColor(.white)
                    
                    Text(formattedTotal)
                        .appFont(.arialBold, size: 14)
                        .foregroundColor(.categoryVitaminsAndSupplements)
                }
                .frame(width: innerSize, height: innerSize)
                .multilineTextAlignment(.center)
            }
            .frame(width: chartSize, height: chartSize)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                let share = shares.first { $0.category == category }
                let percent = share.map { Int(round($0.fraction * 100)) } ?? 0
                
                Text("\(category.displayName) - \(percent)%")
                    .appFont(.arialRegular, size: 12)
                    .foregroundColor(category.chartColor)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
    }
}

extension MonthPeriod {
    func title(locale: Locale = Locale(identifier: "en_US")) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "LLLL, yyyy"
        return formatter.string(from: date)
    }
    
    func adding(months value: Int) -> MonthPeriod {
        var newMonth = month + value
        var newYear = year
        
        while newMonth > 12 {
            newMonth -= 12
            newYear += 1
        }
        
        while newMonth < 1 {
            newMonth += 12
            newYear -= 1
        }
        
        return MonthPeriod(year: newYear, month: newMonth)
    }
}

struct LimitsCardView: View {
    let usages: [LimitUsage]
    let onManageTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Limits")
                    .appFont(.arialBold, size: 22)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onManageTap) {
                    Text("Manage limits")
                        .appFont(.agText, size: 16)
                        .foregroundColor(.appAccentYellow)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sortedUsages, id: \.limit.id) { usage in
                    limitRow(for: usage)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appPrimaryBlue, lineWidth: 2)
                )
        )
    }
    
    private var sortedUsages: [LimitUsage] {
        usages.sorted { lhs, rhs in
            title(for: lhs.limit) < title(for: rhs.limit)
        }
    }
    
    private func limitRow(for usage: LimitUsage) -> some View {
        let spentText = formatCurrency(usage.spent)
        let limitText = formatCurrency(usage.limit.amount)
        let isExceeded = usage.percentUsed > 100
        
        return HStack(spacing: 4) {
            Text("\(title(for: usage.limit)):")
                .appFont(.agText, size: 18)
                .foregroundColor(.white)
            
            Text(spentText)
                .appFont(.agText, size: 18)
                .foregroundColor(isExceeded ? .red : .categoryVitaminsAndSupplements)
            
            Text("/")
                .appFont(.agText, size: 18)
                .foregroundColor(.white)
            
            Text(limitText)
                .appFont(.agText, size: 18)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private func title(for limit: SpendingLimit) -> String {
        if let category = limit.category {
            switch category {
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
        } else {
            return "Total"
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

#Preview {
    let store = PetStore.preview
    store.selectedMonth = MonthPeriod.current()
    
    return NavigationStack {
        PetStatsView(pet: store.pets[0])
            .environmentObject(store)
    }
}

struct CompareCategoryDropdownShape: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
    }
}
