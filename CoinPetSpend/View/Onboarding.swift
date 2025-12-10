import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    
    @State private var currentPage: Int = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onboarding_pet_1",
            title: "Track your pet's expenses",
            subtitle: "Add every purchase for food, vet care, toys and more to see the full picture."
        ),
        OnboardingPage(
            imageName: "onboarding_pet_2",
            title: "Set monthly limits",
            subtitle: "Control spending with monthly limits for each pet or specific categories."
        ),
        OnboardingPage(
            imageName: "onboarding_pet_3",
            title: "Compare and analyze",
            subtitle: "See stats, compare pets and keep your budget under control."
        )
    ]
    
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Image(pages[currentPage].imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height * 2 / 3)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                    
                    bottomContent
                        .frame(height: geo.size.height / 3)
                }
            }
        }
    }
    
    private var bottomContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(pages[currentPage].title)
                    .appFont(.arialBold, size: 28)
                    .foregroundColor(Color.appAccentYellow)
                
                Text(pages[currentPage].subtitle)
                    .appFont(.arialRegular, size: 20)
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.leading)
            
            Spacer()
            
            buttonRow
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var buttonRow: some View {
        HStack {
            Spacer()
            
            Button {
                if isLastPage {
                    hasSeenOnboarding = true
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage += 1
                    }
                }
            } label: {
                Text(isLastPage ? "Get started" : "Next")
                    .appFont(.arialBold, size: 32)
                    .foregroundColor(.appPrimaryBlue)
                    .frame(height: 68)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appAccentYellow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appPrimaryBlue, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
