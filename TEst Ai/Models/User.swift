//
//  User.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import Foundation
import SwiftUI

struct User: Identifiable, Hashable {
    let id: UUID
    var name: String
    var birthDate: Date
    var gender: Gender

    init(id: UUID = UUID(), name: String, birthDate: Date, gender: Gender) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
    }
}

extension User {
    var isChild: Bool {
        let now = Date()
        let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: now)
        let years = ageComponents.year ?? 0
        return years < 18
    }

    var symbolNameConsideringAge: String {
        if isChild {
            // Иконка для ребенка
            return "figure.and.child.holdinghands"
        }
        // Взрослые: иконки по полу
        switch gender {
        case .male:
            return "person.circle.fill"
        case .female:
            return "person.circle.fill"
        case .other:
            return "person.crop.circle.fill"
        }
    }

    var colorConsideringAge: Color {
        if isChild {
            return .teal
        }
        switch gender {
        case .female:
            return .pink
        case .male:
            return .blue
        case .other:
            return .gray
        }
    }
}
