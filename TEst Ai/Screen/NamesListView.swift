//
//  NamesListView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct NamesListView: View {
    @State private var users: [User] = UsersSeed.initial
    @State private var searchText: String = ""

    // Зеркало старого ключа для совместимости
    @AppStorage("primaryUserID") private var legacyPrimaryUserID: String?

    // Кэш сводки билетов по пользователям: UUID -> (bus, metro)
    @State private var ticketSummary: [UUID: (bus: Int, metro: Int)] = [:]

    let onLogout: () -> Void

    private var filteredUsers: [User] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return users }
        return users.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Строка поиска над списком
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(NSLocalizedString("search.placeholder", comment: "Поиск"), text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)

            List {
                ForEach(filteredUsers) { user in
                    NavigationLink {
                        UserDetailView(user: user)
                    } label: {
                        HStack(spacing: 8) {
                            // Метка главного пользователя
                            if isPrimary(user) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }

                            Image(systemName: user.gender.symbolName)
                                .foregroundStyle(user.gender == .female ? .pink : .blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(isPrimary(user) ? .headline : .body)

                                // Подзаголовок с билетами: "bus - 30, metro - 10"
                                if let summary = ticketSummary[user.id] {
                                    let parts = [
                                        summary.bus > 0 ? "bus - \(summary.bus)" : nil,
                                        summary.metro > 0 ? "metro - \(summary.metro)" : nil
                                    ].compactMap { $0 }
                                    if !parts.isEmpty {
                                        Text(parts.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Нет билетов")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                } else {
                                    // Пока не загружено — можно показать плейсхолдер
                                    Text("—")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            if isPrimary(user) {
                                Button {
                                    unsetPrimary()
                                } label: {
                                    Label("Снять главный", systemImage: "star.slash.fill")
                                }
                            } else {
                                Button {
                                    setPrimary(user)
                                } label: {
                                    Label("Сделать главным", systemImage: "star.fill")
                                }
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if isPrimary(user) {
                            // Запрещаем удаление главного — не показываем destructive кнопку
                            Button {
                                // Ничего: можно подсветить, что это главный
                            } label: {
                                Label("Главный", systemImage: "star.fill")
                            }
                            .tint(.gray)
                        } else {
                            Button(role: .destructive) {
                                deleteUser(user)
                            } label: {
                                Label("Удалить", systemImage: "trash.fill")
                            }
                        }
                    }
                    .onAppear {
                        // Обновим сводку для пользователя при появлении строки
                        refreshSummary(for: user)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(NSLocalizedString("logout.button.title", comment: "Выйти"), action: onLogout)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(NSLocalizedString("add.button.title", comment: "Добавить")) {
                    AddNameView { newUser in
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
                    .navigationTitle(NSLocalizedString("new.user.title", comment: "Новый пользователь"))
                }
            }
        }
        .onAppear {
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
    }

    private func refreshSummary(for user: User) {
        let records = TicketWalletStore.load(memberID: user.id.uuidString)
        let bus = records.first(where: { $0.type == .bus })?.remainingRides ?? 0
        let metro = records.first(where: { $0.type == .metro })?.remainingRides ?? 0
        ticketSummary[user.id] = (bus: bus, metro: metro)
    }

    private func refreshAllSummaries() {
        var dict: [UUID: (bus: Int, metro: Int)] = [:]
        for user in users {
            let records = TicketWalletStore.load(memberID: user.id.uuidString)
            let bus = records.first(where: { $0.type == .bus })?.remainingRides ?? 0
            let metro = records.first(where: { $0.type == .metro })?.remainingRides ?? 0
            dict[user.id] = (bus: bus, metro: metro)
        }
        ticketSummary = dict
    }

    private func deleteUser(_ user: User) {
        // Защита: не удаляем главного
        guard !isPrimary(user) else { return }
        users.removeAll { $0.id == user.id }
        // Если удалили кого-то ещё — сводку обновим
        ticketSummary[user.id] = nil
    }

    private func isPrimary(_ user: User) -> Bool {
        ProfileStore.primaryUserID == user.id.uuidString
    }

    private func setPrimary(_ user: User) {
        ProfileStore.primaryUserID = user.id.uuidString
        legacyPrimaryUserID = user.id.uuidString
    }

    private func unsetPrimary() {
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

    private func delete(at offsets: IndexSet) {
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

#Preview {
    NamesListView(onLogout: {})
}
