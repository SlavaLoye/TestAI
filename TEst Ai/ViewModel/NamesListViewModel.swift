import Foundation
import SwiftUI
import Combine

@MainActor
final class NamesListViewModel: SwiftUI.ObservableObject {

    // MARK: - Published state for the View
    @Published var users: [User] = UsersSeed.initial
    @Published var searchText: String = ""
    @Published var ticketSummary: [UUID: (bus: Int, metro: Int)] = [:]
    @Published var showLogoutConfirm: Bool = false

    // Зеркало старого ключа для совместимости (оставляем здесь, чтобы View был «тонким»)
    @AppStorage("primaryUserID") var legacyPrimaryUserID: String?

    // MARK: - Derived data
    var filteredUsers: [User] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return users }
        return users.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Lifecycle
    func onAppear() {
        // Назначаем только если id пустой. Не переопределяем валидный id даже если он не в сид-списке.
        if ProfileStore.primaryUserID.isEmpty {
            if let vyacheslav = users.first(where: { $0.name == "Вячеслав" }) {
                ProfileStore.primaryUserID = vyacheslav.id.uuidString
                legacyPrimaryUserID = vyacheslav.id.uuidString
            } else if let first = users.first {
                ProfileStore.primaryUserID = first.id.uuidString
                legacyPrimaryUserID = first.id.uuidString
            }
        } else {
            // Синхронизируем зеркало старого ключа (однонаправленно)
            if legacyPrimaryUserID != ProfileStore.primaryUserID {
                legacyPrimaryUserID = ProfileStore.primaryUserID
            }
        }

        // Массово обновим сводку для всех пользователей при входе на экран
        refreshAllSummaries()
    }

    // MARK: - Tickets summary
    func refreshSummary(for user: User) {
        let records = TicketWalletStore.load(memberID: user.id.uuidString)
        let bus = records.first(where: { $0.type == .bus })?.remainingRides ?? 0
        let metro = records.first(where: { $0.type == .metro })?.remainingRides ?? 0
        ticketSummary[user.id] = (bus: bus, metro: metro)
    }

    func refreshAllSummaries() {
        var dict: [UUID: (bus: Int, metro: Int)] = [:]
        for user in users {
            let records = TicketWalletStore.load(memberID: user.id.uuidString)
            let bus = records.first(where: { $0.type == .bus })?.remainingRides ?? 0
            let metro = records.first(where: { $0.type == .metro })?.remainingRides ?? 0
            dict[user.id] = (bus: bus, metro: metro)
        }
        ticketSummary = dict
    }

    // MARK: - Primary user
    func isPrimary(_ user: User) -> Bool {
        ProfileStore.primaryUserID == user.id.uuidString
    }

    func setPrimary(_ user: User) {
        ProfileStore.primaryUserID = user.id.uuidString
        legacyPrimaryUserID = user.id.uuidString
    }

    func unsetPrimary() {
        // Временно снимаем — но чтобы UI не остался без главного, сразу назначим "Вячеслава" или первого
        if let vyacheslav = users.first(where: { $0.name == "Вячеслав" }) {
            setPrimary(vyacheslav)
        } else if let first = users.first {
            setPrimary(first)
        } else {
            // Если список пуст — очистим оба ключа
            ProfileStore.primaryUserID = ""
            legacyPrimaryUserID = nil
        }
    }

    // MARK: - Mutations
    func addUser(_ newUser: User) {
        // Нормализуем имя и добавляем пользователя
        let trimmed = newUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var userToAdd = newUser
        userToAdd.name = trimmed
        users.append(userToAdd)

        // Если главного ещё нет — назначим только что добавленного
        if ProfileStore.primaryUserID.isEmpty {
            ProfileStore.primaryUserID = userToAdd.id.uuidString
            legacyPrimaryUserID = userToAdd.id.uuidString
        }
        // И сразу обновим сводку для нового пользователя
        refreshSummary(for: userToAdd)
    }

    func deleteUser(_ user: User) {
        // Защита: не удаляем главного
        guard !isPrimary(user) else { return }
        users.removeAll { $0.id == user.id }
        // Если удалили кого-то ещё — сводку обновим
        ticketSummary[user.id] = nil

        // Если после удаления текущий главный отсутствует — переназначим
        if users.first(where: { $0.id.uuidString == ProfileStore.primaryUserID }) == nil {
            if let vyacheslav = users.first(where: { $0.name == "Вячеслав" }) {
                setPrimary(vyacheslav)
            } else if let first = users.first {
                setPrimary(first)
            } else {
                ProfileStore.primaryUserID = ""
                legacyPrimaryUserID = nil
            }
        }

        // Обновим сводку после удаления
        refreshAllSummaries()
    }

    func delete(at offsets: IndexSet) {
        // Индексы видимого (фильтрованного) списка
        let idsToDelete = offsets
            .map { filteredUsers[$0].id }
            // Фильтруем: не удаляем главного
            .filter { $0.uuidString != ProfileStore.primaryUserID }

        guard !idsToDelete.isEmpty else { return }

        users.removeAll { idsToDelete.contains($0.id) }

        // Если после удаления текущий главный отсутствует — переназначим
        if users.first(where: { $0.id.uuidString == ProfileStore.primaryUserID }) == nil {
            if let vyacheslav = users.first(where: { $0.name == "Вячеслав" }) {
                setPrimary(vyacheslav)
            } else if let first = users.first {
                setPrimary(first)
            } else {
                ProfileStore.primaryUserID = ""
                legacyPrimaryUserID = nil
            }
        }

        // Обновим сводку после удаления
        refreshAllSummaries()
    }
}
