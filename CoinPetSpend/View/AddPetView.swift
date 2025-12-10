import SwiftUI
import UIKit

struct AddPetView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) var dismiss
    
    let petToEdit: Pet?
    
    @State private var name: String = ""
    @State private var selectedKind: PetKind?
    @State private var birthDate: Date?
    
    @State private var photoData: Data?
    
    @State private var showImageSourceDialog = false
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var showKindDropdown = false
    @State private var showCalendarOverlay = false
    @State private var calendarMonth: Date = Date()
    
    private let buttonHorizontalPadding: CGFloat = 69
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60
    
    private var isSaveEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedKind != nil
    }
    
    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }
    
    private var birthDateText: String {
        guard let date = birthDate else { return "Choose" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    init(petToEdit: Pet? = nil) {
        self.petToEdit = petToEdit
        
        if let pet = petToEdit {
            _name = State(initialValue: pet.name)
            _selectedKind = State(initialValue: pet.kind)
            _birthDate = State(initialValue: pet.birthDate)
            _photoData = State(initialValue: pet.photoData)
            _calendarMonth = State(initialValue: pet.birthDate ?? Date())
        } else {
            _name = State(initialValue: "")
            _selectedKind = State(initialValue: nil)
            _birthDate = State(initialValue: nil)
            _photoData = State(initialValue: nil)
            _calendarMonth = State(initialValue: Date())
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppNavigationBar(
                    title: petToEdit == nil ? "ADD A PET" : "EDIT PET",
                    onBack: { dismiss() },
                    onMore: nil
                )
                
                ScrollView {
                    VStack(spacing: 32) {
                        photoSection
                        
                        VStack(spacing: 28) {
                            nameRow
                            kindRow
                                .zIndex(1)
                            birthDateRow
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imageSourceType) { data in
                photoData = data
            }
        }
        .confirmationDialog(
            "Choose source",
            isPresented: $showImageSourceDialog,
            titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
            }
            
            Button("Gallery") {
                imageSourceType = .photoLibrary
                showImagePicker = true
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .overlay {
            if showCalendarOverlay {
                CalendarOverlay(
                    isPresented: $showCalendarOverlay,
                    selectedDate: $birthDate,
                    displayedMonth: $calendarMonth
                )
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var photoSection: some View {
        Button {
            showImageSourceDialog = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.clear)
                    )
                    .frame(width: 180, height: 180)
                
                if let data = photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 176, height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    VStack(spacing: 12) {
                        Image("addPh")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        
                        Text("Add a photo")
                            .appFont(.agText, size: 16)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var nameRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pet's name")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)
            
            TextField("Enter name", text: $name)
                .appFont(.agText, size: 18)
                .foregroundColor(.white)
                .accentColor(.appAccentYellow)
            
            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
        }
        .dynamicTypeSize(.medium)
    }
    
    private var kindRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pet type")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showKindDropdown.toggle()
                }
            } label: {
                HStack {
                    Text(selectedKind?.displayName ?? "Choose")
                        .appFont(.agText, size: 18)
                        .foregroundColor(selectedKind == nil ? .gray : .white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18))
                        .foregroundColor(.appAccentYellow)
                        .rotationEffect(.degrees(showKindDropdown ? 180 : 0))
                }
                .dynamicTypeSize(.medium)
            }
            
            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
                .overlay(
                    GeometryReader { geometry in
                        if showKindDropdown {
                            let width = geometry.size.width * 0.4
                            VStack(spacing: 24) {
                                ForEach(PetKind.allCases) { kind in
                                    Button {
                                        selectedKind = kind
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showKindDropdown = false
                                        }
                                    } label: {
                                        Text(kind.displayName)
                                            .appFont(.arialRegular, size: 16)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 32)
                            .background(
                                PetTypeDropdownShape(cornerRadius: 18)
                                    .fill(Color.appBg)
                                    .overlay(
                                        PetTypeDropdownShape(cornerRadius: 12)
                                            .stroke(Color.appAccentYellow, lineWidth: 2)
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
    
    private var birthDateRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Date of birth")
                .appFont(.arialBold, size: 20)
                .foregroundColor(.white)
            
            Button {
                calendarMonth = birthDate ?? Date()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCalendarOverlay = true
                }
            } label: {
                HStack {
                    Text(birthDateText)
                        .appFont(.agText, size: 18)
                        .foregroundColor(birthDate == nil ? .gray : .white)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.appAccentYellow)
                }
                .dynamicTypeSize(.medium)
            }
            
            Rectangle()
                .fill(Color.appAccentYellow)
                .frame(height: 2)
        }
    }
    
    private var saveButton: some View {
        VStack {
            Button {
                guard let kind = selectedKind else { return }
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let existing = petToEdit {
                    store.updatePet(
                        existing,
                        name: trimmedName,
                        kind: kind,
                        birthDate: birthDate,
                        photoData: photoData
                    )
                } else {
                    store.addPet(
                        name: trimmedName,
                        kind: kind,
                        birthDate: birthDate,
                        photoData: photoData
                    )
                }
                
                dismiss()
            } label: {
                Text("Save")
                    .appFont(.arialBold, size: 32)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSaveEnabled ? Color.appAccentYellow : Color.gray.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appPrimaryBlue, lineWidth: 1)
                    )
                    .foregroundColor(isSaveEnabled ? .appPrimaryBlue : .black.opacity(0.7))
            }
            .buttonStyle(.plain)
            .disabled(!isSaveEnabled)
            
            Text("Can be changed later")
                .appFont(.agText, size: 14)
                .foregroundColor(.white)
                .padding(.top, 18)
        }
    }
}

#Preview {
    AddPetView()
        .environmentObject(PetStore())
        .preferredColorScheme(.dark)
}

struct CalendarOverlay: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date?
    @Binding var displayedMonth: Date
    
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        cal.firstWeekday = 2
        return cal
    }()
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: displayedMonth)
    }
    
    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var result: [Date?] = []
        
        for _ in 0..<offset {
            result.append(nil)
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                result.append(date)
            }
        }
    
        while result.count < 42 {
            result.append(nil)
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            VStack {
                VStack(spacing: 0) {
                    HStack {
                        Text(monthTitle)
                            .appFont(.arialBold, size: 22)
                            .foregroundColor(.appAccentYellow)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button {
                                moveMonth(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appAccentYellow)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            
                            Button {
                                moveMonth(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appAccentYellow)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    let weekdaySymbols = calendar.veryShortWeekdaySymbols.map { $0.uppercased() }
                    
                    HStack(spacing: 0) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .appFont(.agText, size: 16)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    Rectangle()
                        .fill(Color.appPrimaryBlue)
                        .frame(height: 1)
                        .padding(.bottom, 8)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                        ForEach(0..<days.count, id: \.self) { index in
                            if let date = days[index] {
                                dayCell(for: date)
                            } else {
                                Text("")
                                    .frame(height: 36)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appPrimaryBlue, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.appBg)
                        )
                )
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.dateComponents([.month], from: date).month ==
                              calendar.dateComponents([.month], from: displayedMonth).month
        
        return Button {
            selectedDate = date
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .appFont(.agText, size: 16)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appPrimaryBlue)
                        } else if isToday {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appAccentYellow, lineWidth: 2)
                        } else {
                            Color.clear
                        }
                    }
                )
                .foregroundColor(isSelected ? .appAccentYellow : (isToday ? .appAccentYellow : .white))
        }
        .buttonStyle(.plain)
        .disabled(!isCurrentMonth)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
}

struct PetTypeDropdownShape: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(-180),
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r))
        
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(-180),
            endAngle: .degrees(-270),
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
        
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.minY))
        
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    AddPetView()
        .environmentObject(PetStore())
        .preferredColorScheme(.dark)
}

