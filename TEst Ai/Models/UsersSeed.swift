//
//  UsersSeed.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import Foundation

enum UsersSeed {
    static let initial: [User] = [
        // Главный пользователь по умолчанию — Вячеслав
        User(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Вячеслав",
            birthDate: Date(timeIntervalSince1970: 441763200),
            gender: .male
        ),
        User(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Мария",
            birthDate: Date(timeIntervalSince1970: 567993600),
            gender: .female
        ),
        User(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Иван",
            birthDate: Date(timeIntervalSince1970: 599616000),
            gender: .male
        ),
        User(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "София",
            birthDate: Date(timeIntervalSince1970: 757296000),
            gender: .female
        ),
        User(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            name: "Дмитрий",
            birthDate: Date(timeIntervalSince1970: 410227200),
            gender: .male
        ),
        User(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            name: "Анна",
            birthDate: Date(timeIntervalSince1970: 662256000),
            gender: .female
        ),
        User(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            name: "Егор",
            birthDate: Date(timeIntervalSince1970: 819936000),
            gender: .male
        ),
        User(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            name: "Полина",
            birthDate: Date(timeIntervalSince1970: 851558400),
            gender: .female
        )
    ]
}

