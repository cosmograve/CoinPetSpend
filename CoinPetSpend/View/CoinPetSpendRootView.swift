import SwiftUI

struct CoinPetSpendRootView: View {
    @StateObject private var store = PetStore()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if hasSeenOnboarding {
                    PetsView()
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    CoinPetSpendRootView()
        .environmentObject(PetStore.preview)
}
