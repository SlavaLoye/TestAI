// ProfileStore.swift
// Центральное хранилище профиля в UserDefaults

import Foundation

enum ProfileStore {
    private enum Keys {
        static let primaryUserID = "profile.primaryUserID"
        static let email = "profile.email"
        static let name = "profile.name"
        static let birthDate = "profile.birthDate" // TimeInterval
        static let gender = "profile.gender"       // rawValue Gender
        static let cardBrand = "profile.card.brand"
        static let cardLast4 = "profile.card.last4"
    }

    private static var defaults: UserDefaults { .standard }

    // MARK: - Bootstrap по умолчанию
    static func ensureDefaultProfile() {
        // Если нет primaryUserID — попробуем взять "Вячеслава" из сидов, затем первого пользователя, иначе создадим новый
        if defaults.string(forKey: Keys.primaryUserID) == nil || (defaults.string(forKey: Keys.primaryUserID)?.isEmpty ?? true) {
            if let vyacheslav = UsersSeed.initial.first(where: { $0.name == "Вячеслав" }) {
                defaults.set(vyacheslav.id.uuidString, forKey: Keys.primaryUserID)
                // Перенесём базовые поля в профиль
                defaults.set(vyacheslav.name, forKey: Keys.name)
                defaults.set(vyacheslav.birthDate.timeIntervalSince1970, forKey: Keys.birthDate)
                defaults.set(vyacheslav.gender.rawValue, forKey: Keys.gender)
            } else if let first = UsersSeed.initial.first {
                defaults.set(first.id.uuidString, forKey: Keys.primaryUserID)
                defaults.set(first.name, forKey: Keys.name)
                defaults.set(first.birthDate.timeIntervalSince1970, forKey: Keys.birthDate)
                defaults.set(first.gender.rawValue, forKey: Keys.gender)
            } else {
                // Фолбэк: если сидов нет — сгенерируем id
                let id = UUID().uuidString
                defaults.set(id, forKey: Keys.primaryUserID)
            }
        }

        // Остальные поля — если пустые, заполним дефолтами
        if defaults.string(forKey: Keys.email) == nil {
            defaults.set("slavaloye@yandex.ru", forKey: Keys.email)
        }
        if defaults.string(forKey: Keys.name) == nil || (defaults.string(forKey: Keys.name)?.isEmpty ?? true) {
            // Если ensureDefaultProfile уже перенёс имя из сидов, это условие не выполнится.
            defaults.set("Вячеслав", forKey: Keys.name)
        }
        if defaults.object(forKey: Keys.birthDate) == nil {
            let date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
            defaults.set(date.timeIntervalSince1970, forKey: Keys.birthDate)
        }
        if defaults.string(forKey: Keys.gender) == nil || (defaults.string(forKey: Keys.gender)?.isEmpty ?? true) {
            defaults.set("male", forKey: Keys.gender)
        }
        // Карта не обязательна — оставим пустой по умолчанию
    }

    // MARK: - Свойства профиля
    static var primaryUserID: String {
        get {
            if let id = defaults.string(forKey: Keys.primaryUserID) {
                return id
            }
            ensureDefaultProfile()
            return defaults.string(forKey: Keys.primaryUserID) ?? UUID().uuidString
        }
        set { defaults.set(newValue, forKey: Keys.primaryUserID) }
    }

    static var email: String {
        get {
            defaults.string(forKey: Keys.email) ?? {
                ensureDefaultProfile()
                return defaults.string(forKey: Keys.email) ?? ""
            }()
        }
        set { defaults.set(newValue, forKey: Keys.email) }
    }

    static var name: String {
        get {
            defaults.string(forKey: Keys.name) ?? {
                ensureDefaultProfile()
                return defaults.string(forKey: Keys.name) ?? ""
            }()
        }
        set { defaults.set(newValue, forKey: Keys.name) }
    }

    static var birthDate: Date {
        get {
            if let ti = defaults.object(forKey: Keys.birthDate) as? TimeInterval {
                return Date(timeIntervalSince1970: ti)
            }
            ensureDefaultProfile()
            let ti = defaults.object(forKey: Keys.birthDate) as? TimeInterval ?? Date().timeIntervalSince1970
            return Date(timeIntervalSince1970: ti)
        }
        set {
            defaults.set(newValue.timeIntervalSince1970, forKey: Keys.birthDate)
        }
    }

    static var genderRaw: String {
        get {
            defaults.string(forKey: Keys.gender) ?? {
                ensureDefaultProfile()
                return defaults.string(forKey: Keys.gender) ?? "other"
            }()
        }
        set { defaults.set(newValue, forKey: Keys.gender) }
    }

    // Удобный доступ, если нужен enum Gender
    static var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .other }
        set { genderRaw = newValue.rawValue }
    }

    // Демо-данные карты
    static var cardBrand: String {
        get { defaults.string(forKey: Keys.cardBrand) ?? "" }
        set { defaults.set(newValue, forKey: Keys.cardBrand) }
    }

    static var cardLast4: String {
        get { defaults.string(forKey: Keys.cardLast4) ?? "" }
        set { defaults.set(newValue, forKey: Keys.cardLast4) }
    }
}
