//
//  Font+ext.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 08.12.2025.
//

import SwiftUI

enum AppFont {
    case sfProBold
    case arialRegular
    case arialBold
    case agH1
    case agText
}

struct AppFontModifier: ViewModifier {
    let font: AppFont
    let size: CGFloat
    
    func body(content: Content) -> some View {
        let swiftUIFont: Font
        
        switch font {
        case .sfProBold:
            swiftUIFont = .system(size: size, weight: .bold)
        case .arialRegular:
            swiftUIFont = .custom("ArialMT", size: size)
        case .arialBold:
            swiftUIFont = .custom("Arial-BoldMT", size: size)
        case .agH1:
            swiftUIFont = .custom("AgH1", size: size)
        case .agText:
            swiftUIFont = .custom("AgText", size: size)
        }
        
        return content
            .font(swiftUIFont)
            .dynamicTypeSize(.medium)
    }
}

extension View {
    func appFont(_ font: AppFont, size: CGFloat) -> some View {
        modifier(AppFontModifier(font: font, size: size))
    }
}
