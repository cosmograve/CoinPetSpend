
import SwiftUI

struct PetLimitsView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAddLimit = false
    let pet: Pet

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
            Color.appBg
                .ignoresSafeArea()

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
                            VStack(spacing: 16) {
                                ForEach(petLimits) { limit in
                                    Text("Limit card for \(limit.id.uuidString)")
                                        .foregroundColor(.white)
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, contentBottomPadding)
                }
            }
        }
        .overlay(alignment: .bottom) {
            PrimaryActionButton(title: "+ New Limit") {
                showAddLimit.toggle()
            }
            .frame(height: buttonHeight)
            .padding(.horizontal, buttonHorizontalPadding)
            .padding(.bottom, buttonOffsetFromBottom)
        }
        .navigationDestination(isPresented: $showAddLimit) {
            AddLimitView(pet: pet)
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
            Spacer(minLength: 80)

            Text("NO LIMITS SET FOR THIS PET")
                .appFont(.arialBold, size: 24)
                .foregroundColor(.appAccentYellow)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
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
