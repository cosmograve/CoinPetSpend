import SwiftUI

struct CoinPetSpendRootView: View {
    @StateObject private var store = PetStore()
    
    var body: some View {
        NavigationStack {
            PetsView()
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    CoinPetSpendRootView()
        .environmentObject(PetStore.preview)
}
