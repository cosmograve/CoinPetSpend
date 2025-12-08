//
//  Pet.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 04.12.2025.
//

import Foundation

enum PetKind: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case dog = "dog"
    case cat = "cat"
    case parrot = "parrot"
    case rodent = "rodent"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .dog:
            return "Dog"
        case .cat:
            return "Cat"
        case .parrot:
            return "Parrot"
        case .rodent:
            return "Rodent"
        case .other:
            return "Other"
        }
    }
}

struct Pet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var kind: PetKind
    var birthDate: Date?
    var photoData: Data?
    
    init(
        id: UUID = UUID(),
        name: String,
        kind: PetKind,
        birthDate: Date? = nil,
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.birthDate = birthDate
        self.photoData = photoData
    }
}
