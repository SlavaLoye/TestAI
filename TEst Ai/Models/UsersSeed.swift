//
//  UsersSeed.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import Foundation

enum UsersSeed {
    static let initial: [User] = [
        // Главный пользователь по умолчанию — Вячеслав (mister)
        User(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Вячеслав",
            birthDate: Date(timeIntervalSince1970: 441763200), // ~1984-01-01
            gender: .male,
            avatarImageName: "mister"
        ),

        // Miss 18–33
        User(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Мария",
            birthDate: Date(timeIntervalSince1970: 915148800), // ~1999-01-01
            gender: .female,
            avatarImageName: "miss"
        ),

        // Mister 18–33
        User(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Иван",
            birthDate: Date(timeIntervalSince1970: 883612800), // ~1998-01-01
            gender: .male,
            avatarImageName: "mister"
        ),

        // Girl 7–12 (ассет: gerl)
        User(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "София",
            birthDate: Date(timeIntervalSince1970: 1356998400), // ~2013-01-01
            gender: .female,
            avatarImageName: "gerl"
        ),

        // Mister 18–33
        User(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            name: "Дмитрий",
            birthDate: Date(timeIntervalSince1970: 883612800), // ~1998-01-01
            gender: .male,
            avatarImageName: "mister"
        ),

        // Miss 18–33
        User(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            name: "Анна",
            birthDate: Date(timeIntervalSince1970: 946684800), // ~2000-01-01
            gender: .female,
            avatarImageName: "miss"
        ),

        // Boy 7–12
        User(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            name: "Егор",
            birthDate: Date(timeIntervalSince1970: 1420070400), // ~2015-01-01
            gender: .male,
            avatarImageName: "boy"
        ),

        // Girl 7–12 (ассет: gerl)
        User(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            name: "Полина",
            birthDate: Date(timeIntervalSince1970: 1451606400), // ~2016-01-01
            gender: .female,
            avatarImageName: "gerl"
        ),

        // Grandmother 60+ (ассет: grandMather)
        User(
            id: UUID(),
            name: "Бабушка",
            birthDate: Date(timeIntervalSince1970: -315619200), // ~1960-01-01
            gender: .female,
            avatarImageName: "grandMather"
        ),

        // Grandfather 60+ (ассет: grandPhater)
        User(
            id: UUID(),
            name: "Дедушка",
            birthDate: Date(timeIntervalSince1970: -410227200), // ~1957-01-01
            gender: .male,
            avatarImageName: "grandPhater"
        )
    ]
}
