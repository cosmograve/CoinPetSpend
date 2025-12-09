import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    
    @State private var selectedCategory: ExpenseCategory?
    @State private var showCategoryDropdown = false
    
    @State private var amountText: String = ""
    @State private var selectedDate: Date = Date()
    
    @State private var note: String = ""
    
    @State private var showCalendarOverlay = false
    @State private var calendarMonth: Date = Date()
    
    private let buttonHorizontalPadding: CGFloat = 38
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60
    
    private var isAddEnabled: Bool {
        guard
            selectedCategory != nil,
            let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")),
            amount > 0
        else {
            return false
        }
        return true
    }
    
    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppNavigationBar(
                    title: "ADD EXPENSE",
                    onBack: { dismiss() },
                    onMore: nil
                )
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        
                        VStack(spacing: 28) {
                            categoryRow
                                .zIndex(1)
                            amountRow
                            dateRow
                            noteRow
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
            addButton
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
                    displayedMonth: $calendarMonth
                )
            }
        }
        .ignoresSafeArea(.keyboard)
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
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
                    
                    Image(systemName: showCategoryDropdown ? "chevron.up" : "chevron.down")
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
    
    private var dateRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)
            
            Button {
                calendarMonth = selectedDate
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCalendarOverlay = true
                }
            } label: {
                HStack {
                    Text(dateText(selectedDate))
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
    
    private var noteRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)
            
            TextField("Text", text: $note, axis: .vertical)
                .lineLimit(1...4)
                .appFont(.agText, size: 18)
                .foregroundColor(.white)
                .accentColor(.appAccentYellow)
                .dynamicTypeSize(.medium)
            
            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
        }
    }
    
    private var addButton: some View {
        VStack {
            Button {
                addExpense()
            } label: {
                Text("Add Expense")
                    .appFont(.arialBold, size: 24)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isAddEnabled ? Color.appAccentYellow : Color.gray.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
                    .foregroundColor(isAddEnabled ? .appPrimaryBlue : .black.opacity(0.7))
            }
            .buttonStyle(.plain)
            .disabled(!isAddEnabled)
        }
    }
    
    private func addExpense() {
        guard let category = selectedCategory else { return }
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")),
              amount > 0 else { return }
        
        store.addExpense(
            for: pet,
            category: category,
            amount: amount,
            date: selectedDate,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        )
        
        dismiss()
    }
    
    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}

#Preview {
    let store = PetStore.preview
    return NavigationStack {
        AddExpenseView(pet: store.pets[0])
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
