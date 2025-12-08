//
//  NavBar.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 08.12.2025.
//

import SwiftUI

struct AppNavigationBar: View {
    let title: String
    let onBack: (() -> Void)?
    let onMore: (() -> Void)?
    
    private let sideButtonWidth: CGFloat = 44
    
    var body: some View {
        ZStack {
            Color.appPrimaryBlue
            
            HStack {
                if let onBack = onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(.appAccentYellow)
                    }
                    .frame(width: sideButtonWidth, alignment: .leading)
                } else {
                    Spacer()
                        .frame(width: sideButtonWidth)
                }
                
                Spacer()
                
                Text(title)
                    .appFont(.arialBold, size: 24)
                    .foregroundColor(.appAccentYellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                if let onMore = onMore {
                    Button(action: onMore) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appAccentYellow)
                    }
                    .frame(width: sideButtonWidth, alignment: .trailing)
                } else {
                    Spacer()
                        .frame(width: sideButtonWidth)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .background(Color.appPrimaryBlue)
    }
}

extension UIApplication {
    var appKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    var appSafeAreaInsets: UIEdgeInsets {
        appKeyWindow?.safeAreaInsets ?? .zero
    }
}

