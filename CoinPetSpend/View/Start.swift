
import SwiftUI

struct Start: View {
    @State private var progress: CGFloat = 0.2

    var body: some View {
        ZStack {
            Image(.startBg)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack {
                Spacer()
                Image(.startLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                Spacer()
                VStack(spacing: 12) {
                    Text("Loading...")
                        .appFont(.arialBold, size: 20)
                        .foregroundStyle(.white)
                    
                    GeometryReader { geo in
                        ZStack {
                            Capsule()
                                .fill(.white)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "09E4FF"), lineWidth: 3)
                                )
                            
                            HStack(spacing: 0) {
                                Capsule()
                                    .fill(Color.appAccentYellow)
                                    .frame(width: geo.size.width * progress)
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .frame(height: 24)
                    .padding(20)

                }

                Spacer()
            }
            
            
        }
    }
}

#Preview {
    Start()
}
