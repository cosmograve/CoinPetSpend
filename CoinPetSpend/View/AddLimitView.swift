import SwiftUI

struct AddLimitView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss

    let pet: Pet
    let limitToEdit: SpendingLimit?

    @State private var selectedCategory: ExpenseCategory?
    @State private var showCategoryDropdown = false

    @State private var amountText: String = ""
    @State private var selectedMonth: MonthPeriod = MonthPeriod.current()

    @State private var selectedDate: Date = Date()
    @State private var showCalendarOverlay = false
    @State private var calendarMonth: Date = Date()

    private let buttonHorizontalPadding: CGFloat = 38
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60

    private var isSaveEnabled: Bool {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")),
              amount > 0 else { return false }
        return true
    }

    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }

    private var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate)
    }

    init(pet: Pet, limitToEdit: SpendingLimit? = nil) {
        self.pet = pet
        self.limitToEdit = limitToEdit

        let now = Date()
        _selectedDate = State(initialValue: now)
        _calendarMonth = State(initialValue: now)

        let currentPeriod = MonthPeriod.current()
        _selectedMonth = State(initialValue: currentPeriod)

        if let limit = limitToEdit {
            _selectedCategory = State(initialValue: limit.category)
            _amountText = State(initialValue: "\(limit.amount)")

            let calendar = Calendar(identifier: .gregorian)
            var comps = DateComponents()
            comps.year = limit.month.year
            comps.month = limit.month.month
            comps.day = 1
            let dateFromLimit = calendar.date(from: comps) ?? now

            _selectedMonth = State(initialValue: limit.month)
            _selectedDate = State(initialValue: dateFromLimit)
            _calendarMonth = State(initialValue: dateFromLimit)
        } else {
            _selectedCategory = State(initialValue: nil)
            _amountText = State(initialValue: "")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavigationBar(
                    title: limitToEdit == nil ? "NEW LIMIT" : "EDIT LIMIT",
                    onBack: { dismiss() },
                    onMore: nil
                )

                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        VStack(spacing: 28) {
                            categoryRow.zIndex(1)
                            amountRow
                            monthRow
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, contentBottomPadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .overlay(alignment: .bottom) {
            saveButton
                .frame(height: buttonHeight)
                .padding(.horizontal, buttonHorizontalPadding)
                .padding(.bottom, buttonOffsetFromBottom)
        }
        .overlay {
            if showCalendarOverlay {
                CalendarOverlay(
                    isPresented: $showCalendarOverlay,
                    selectedDate: Binding<Date?>(
                        get: { selectedDate },
                        set: { if let newValue = $0 { selectedDate = newValue } }
                    ),
                    displayedMonth: Binding<Date>(
                        get: { calendarMonth },
                        set: { newMonth in
                            calendarMonth = newMonth
                            selectedDate = Calendar.current.date(from: DateComponents(
                                year: Calendar.current.component(.year, from: newMonth),
                                month: Calendar.current.component(.month, from: newMonth),
                                day: 1
                            )) ?? newMonth
                        }
                    )
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
                    .foregroundColor(.appAccentYellow)
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            headerAvatar.frame(width: 120, height: 120)
            Text(pet.name)
                .appFont(.arialBold, size: 28)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerAvatar: some View {
        Group {
            if let data = pet.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.appPrimaryBlue, lineWidth: 2))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBg)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.appPrimaryBlue, lineWidth: 2))
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

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Category")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCategoryDropdown.toggle()
                }
            } label: {
                HStack {
                    Text(selectedCategory?.displayName ?? "Choose")
                        .appFont(.agText, size: 18)
                        .foregroundColor(selectedCategory == nil ? .gray : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18))
                        .foregroundColor(.appAccentYellow)
                        .rotationEffect(.degrees(showCategoryDropdown ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
                .overlay(
                    GeometryReader { geometry in
                        if showCategoryDropdown {
                            let width = geometry.size.width * 0.6
                            VStack(spacing: 18) {
                                ForEach(ExpenseCategory.allCases) { category in
                                    Button {
                                        selectedCategory = category
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showCategoryDropdown = false
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .strokeBorder(category.color, lineWidth: 2)
                                                .frame(width: 16, height: 16)
                                                .overlay(
                                                    Circle()
                                                        .fill(selectedCategory == category ? category.color : .clear)
                                                        .frame(width: 10, height: 10)
                                                )
                                            Text(category.displayName)
                                                .appFont(.arialRegular, size: 14)
                                                .foregroundColor(category.color)
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 24)
                            .background(
                                PetTypeDropdownShape(cornerRadius: 12)
                                    .fill(Color.appBg)
                                    .overlay(
                                        PetTypeDropdownShape(cornerRadius: 12)
                                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                                    )
                            )
                            .frame(width: width, alignment: .leading)
                            .offset(x: geometry.size.width - width, y: 1)
                        }
                    }
                )
        }
    }

    private var amountRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Amount ($)")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)

            TextField("0.00", text: $amountText)
                .keyboardType(.decimalPad)
                .appFont(.agText, size: 18)
                .foregroundColor(.white)
                .accentColor(.appAccentYellow)

            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
        }
    }

    private var monthRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Month")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)

            Button {
                calendarMonth = selectedDate
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCalendarOverlay = true
                }
            } label: {
                HStack {
                    Text(monthText)
                        .appFont(.agText, size: 18)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.appAccentYellow)
                }
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
        }
    }

    private var saveButton: some View {
        VStack {
            Button {
                saveLimit()
            } label: {
                Text("Save Limit")
                    .appFont(.arialBold, size: 24)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSaveEnabled ? Color.appAccentYellow : Color.gray.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
                    .foregroundColor(isSaveEnabled ? .appPrimaryBlue : .black.opacity(0.7))
            }
            .buttonStyle(.plain)
            .disabled(!isSaveEnabled)
        }
    }

    private func saveLimit() {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")),
              amount > 0 else { return }

        let comps = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        let period = MonthPeriod(
            year: comps.year ?? MonthPeriod.current().year,
            month: comps.month ?? MonthPeriod.current().month
        )

        if let existing = limitToEdit {
            store.updateLimit(
                existing,
                for: pet,
                category: selectedCategory,
                month: period,
                amount: amount
            )
        } else {
            store.addLimit(
                for: pet,
                category: selectedCategory,
                month: period,
                amount: amount
            )
        }

        dismiss()
    }
}

#Preview {
    let store = PetStore.preview
    return NavigationStack {
        AddLimitView(pet: store.pets[0])
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
