import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    // Публичное состояние для View
    @Published var primaryUserID: String = ""
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: Gender = .other
    @Published var cardBrand: String = ""
    @Published var cardLast4: String = ""

    // Derived
    var isCardPresent: Bool {
        !cardBrand.isEmpty && !cardLast4.isEmpty
    }

    // MARK: - Lifecycle
    init() {
        load()
    }

    func load() {
        // Обеспечим дефолтные значения в хранилище
        ProfileStore.ensureDefaultProfile()

        // Считаем состояние из хранилища
        primaryUserID = ProfileStore.primaryUserID
        email = ProfileStore.email
        name = ProfileStore.name
        birthDate = ProfileStore.birthDate
        gender = ProfileStore.gender
        cardBrand = ProfileStore.cardBrand
        cardLast4 = ProfileStore.cardLast4
    }

    func save() {
        // Валидация/нормализация по необходимости
        ProfileStore.primaryUserID = primaryUserID
        ProfileStore.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        ProfileStore.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        ProfileStore.birthDate = birthDate
        ProfileStore.gender = gender
        ProfileStore.cardBrand = cardBrand.trimmingCharacters(in: .whitespacesAndNewlines)
        ProfileStore.cardLast4 = cardLast4.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resetCard() {
        cardBrand = ""
        cardLast4 = ""
        save()
    }

    // Удобные методы для экрана
    func updateName(_ newName: String) {
        name = newName
    }

    func updateEmail(_ newEmail: String) {
        email = newEmail
    }

    func updateBirthDate(_ date: Date) {
        birthDate = date
    }

    func updateGender(_ g: Gender) {
        gender = g
    }
}
