//
//  Color+ext.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 04.12.2025.
//

import SwiftUI

extension Color {
    static let appBg = Color(hex: "1D1D1D")
    static let appPrimaryBlue = Color(hex: "0B3FFA")
    static let appAccentYellow = Color(hex: "FFE600")
    static let categoryFood = Color(hex: "FFE600")
    static let categoryVeterinaryCare = Color(hex: "09E4FF")
    static let categoryToys = Color(hex: "ED1810")
    static let categoryGrooming = Color(hex: "0B3FFA")
    static let categoryAccessories = Color(hex: "9500FF")
    static let categoryVitaminsAndSupplements = Color(hex: "0AC600")
    static let categoryOther = Color(hex: "FF0095")
    
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        
        let r, g, b, a: Double
        
        if cleaned.count == 8 {
            a = Double((value & 0xFF000000) >> 24) / 255.0
            r = Double((value & 0x00FF0000) >> 16) / 255.0
            g = Double((value & 0x0000FF00) >> 8) / 255.0
            b = Double(value & 0x000000FF) / 255.0
        } else {
            a = 1.0
            r = Double((value & 0xFF0000) >> 16) / 255.0
            g = Double((value & 0x00FF00) >> 8) / 255.0
            b = Double(value & 0x0000FF) / 255.0
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
