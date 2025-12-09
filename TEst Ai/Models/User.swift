//
//  User.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import Foundation

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
