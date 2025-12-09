//
//  Gender.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import Foundation

enum Gender: String, CaseIterable, Hashable, Identifiable {
    
    case male
    case female
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return NSLocalizedString("gender.male", comment: "Мужской")
        case .female: return NSLocalizedString("gender.female", comment: "Женский")
        case .other: return NSLocalizedString("gender.other", comment: "Другое")
        }
    }

    var symbolName: String {
        switch self {
        case .male: return "person.circle.fill"
        case .female: return "person.circle.fill"
        case .other: return "person.crop.circle.fill"
        }
    }
}
