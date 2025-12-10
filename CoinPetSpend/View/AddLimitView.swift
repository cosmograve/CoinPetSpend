

import SwiftUI

struct AddLimitView: View {
    // MARK: - Dependencies
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss

    // Питомец, для которого создаём лимит
    let pet: Pet

    // MARK: - Category state
    @State private var selectedCategory: ExpenseCategory?
    @State private var showCategoryDropdown = false

    // MARK: - Amount state
    @State private var amountText: String = ""

    // MARK: - Month state (берём месяц из календаря)
    @State private var selectedDate: Date = Date()          // любая дата внутри нужного месяца
    @State private var showCalendarOverlay = false          // показываем/скрываем оверлей
    @State private var calendarMonth: Date = Date()         // текущий отображаемый месяц в календаре

    // MARK: - Layout constants
    private let buttonHorizontalPadding: CGFloat = 38
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60

    // Можно сохранять, только если введена сумма > 0
    private var isSaveEnabled: Bool {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")),
              amount > 0 else {
            return false
        }
        return true
    }

    // Отступ контента снизу, чтобы скролл не заходил под кнопку
    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }

    // Текст для выбранного месяца (пример: "June 2025")
    private var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Фон всего экрана
            Color.appBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Кастомный навбар
                AppNavigationBar(
                    title: "NEW LIMIT",
                    onBack: { dismiss() },
                    onMore: nil
                )

                // Основной скролл
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection

                        VStack(spacing: 28) {
                            categoryRow
                                .zIndex(1)          // чтобы дропдаун был над остальным
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
        // Кнопка "Save Limit" в оверлее внизу
        .overlay(alignment: .bottom) {
            saveButton
                .frame(height: buttonHeight)
                .padding(.horizontal, buttonHorizontalPadding)
                .padding(.bottom, buttonOffsetFromBottom)
        }
        // Оверлей календаря (тот же, что и на других экранах)
        .overlay {
            if showCalendarOverlay {
                CalendarOverlay(
                    isPresented: $showCalendarOverlay,
                    // Берём дату из selectedDate, а при выборе дня обновляем её
                    selectedDate: Binding<Date?>(
                        get: { selectedDate },
                        set: { if let newValue = $0 { selectedDate = newValue } }
                    ),
                    displayedMonth: $calendarMonth
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        // Тулбар над клавиатурой с кнопкой "Done"
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .foregroundColor(.appAccentYellow)
            }
        }
    }

    // MARK: - Keyboard helper

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    // MARK: - Header (аватар + имя)

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

    // MARK: - Category row (как в AddExpenseView)

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
                .dynamicTypeSize(.medium)
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
                                                        .fill(
                                                            selectedCategory == category
                                                            ? category.color
                                                            : Color.clear
                                                        )
                                                        .frame(width: 10, height: 10)
                                                )

                                            Text(category.displayName)
                                                .appFont(.arialRegular, size: 14)
                                                .foregroundColor(category.color)

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
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
                            .offset(
                                x: geometry.size.width - width,
                                y: 1
                            )
                        }
                    }
                )
        }
    }

    // MARK: - Amount row

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
                .dynamicTypeSize(.medium)

            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
        }
    }

    private var monthRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mounth")
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
                .dynamicTypeSize(.medium)
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

        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.year, .month], from: selectedDate)
        let period = MonthPeriod(
            year: comps.year ?? MonthPeriod.current().year,
            month: comps.month ?? MonthPeriod.current().month
        )

        
        store.addLimit(for: pet, category: selectedCategory, month: period, amount: amount)

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
