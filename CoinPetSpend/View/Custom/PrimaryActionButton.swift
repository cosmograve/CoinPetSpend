import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .appFont(.arialBold, size: 32)
                .foregroundColor(.appPrimaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appAccentYellow)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.appBg.ignoresSafeArea()
        PrimaryActionButton(title: "Add A Pet", action: {})
            .padding(.horizontal, 70)
    }
}
