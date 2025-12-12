//
//  NamesListView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct NamesListView: View {
    @StateObject private var vm = NamesListViewModel()

    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Строка поиска над списком
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(NSLocalizedString("search.placeholder", comment: "Поиск"), text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
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
                Section {
                    ForEach(vm.filteredUsers) { user in
                        NavigationLink {
                            UserDetailView(user: user)
                        } label: {
                            UserCardRow(
                                user: user,
                                isPrimary: vm.isPrimary(user),
                                summary: vm.ticketSummary[user.id]
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if vm.isPrimary(user) {
                                Button {
                                    // Ничего: подсветка, что это главный
                                } label: {
                                    Label("Главный", systemImage: "star.fill")
                                }
                                .tint(.gray)
                            } else {
                                Button(role: .destructive) {
                                    vm.deleteUser(user)
                                } label: {
                                    Label("Удалить", systemImage: "trash.fill")
                                }
                            }
                        }
                        .contextMenu {
                            if vm.isPrimary(user) {
                                Button {
                                    vm.unsetPrimary()
                                } label: {
                                    Label("Снять главный", systemImage: "star.slash.fill")
                                }
                            } else {
                                Button {
                                    vm.setPrimary(user)
                                } label: {
                                    Label("Сделать главным", systemImage: "star.fill")
                                }
                            }
                        }
                        .onAppear {
                            vm.refreshSummary(for: user)
                        }
                    }
                    .onDelete(perform: vm.delete)
                }
            }
            .listStyle(.insetGrouped)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(NSLocalizedString("logout.button.title", comment: "Выйти")) {
                    vm.showLogoutConfirm = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(NSLocalizedString("add.button.title", comment: "Добавить")) {
                    AddNameView { newUser in
                        vm.addUser(newUser)
                    }
                    .navigationTitle(NSLocalizedString("new.user.title", comment: "Новый пользователь"))
                }
            }
        }
        .alert(
            NSLocalizedString("logout.confirm.title", comment: "Выход"),
            isPresented: $vm.showLogoutConfirm
        ) {
            Button(NSLocalizedString("logout.confirm.cancel", comment: "Отмена"), role: .cancel) { }
            Button(NSLocalizedString("logout.confirm.ok", comment: "Выйти"), role: .destructive) {
                onLogout()
            }
        } message: {
            Text(NSLocalizedString("logout.confirm.message", comment: "Вы действительно хотите выйти?"))
        }
        .onAppear {
            vm.onAppear()
        }
    }
}

private struct UserCardRow: View {
    let user: User
    let isPrimary: Bool
    let summary: (bus: Int, metro: Int)?

    // Фирменные цвета
    private let brandBlue1 = Color(red: 0.30, green: 0.64, blue: 0.96)
    private let brandBlue2 = Color(red: 0.18, green: 0.49, blue: 0.88)
    private let brandRed1 = Color(red: 1.00, green: 0.27, blue: 0.27)
    private let brandRed2 = Color(red: 0.90, green: 0.10, blue: 0.10)

    var body: some View {
        ZStack {
            // Карточка
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

            HStack(spacing: 12) {
                // Аватар: если есть фото — показываем его, иначе SF Symbol
                if let avatar = user.avatarImageName, !avatar.isEmpty {
                    Image(avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [brandBlue1.opacity(0.18), brandBlue2.opacity(0.10)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: user.symbolNameConsideringAge)
                            .foregroundStyle(user.colorConsideringAge)
                            .font(.system(size: 20, weight: .semibold))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if isPrimary {
                            Label("Главный", systemImage: "star.fill")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(LinearGradient(colors: [brandRed1, brandRed2], startPoint: .top, endPoint: .bottom))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color(.systemBackground))
                                )
                                .overlay(
                                    Capsule().stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                                )
                        }
                    }

                    // Подзаголовок с билетами
                    Group {
                        if let summary {
                            let parts = [
                                summary.bus > 0 ? "bus - \(summary.bus)" : nil,
                                summary.metro > 0 ? "metro - \(summary.metro)" : nil
                            ].compactMap { $0 }

                            if !parts.isEmpty {
                                Text(parts.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(NSLocalizedString("tickets.none", comment: "No tickets"))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()
                // ВАЖНО: не рисуем свою стрелку — её добавляет NavigationLink.
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .contentShape(Rectangle())
        .animation(.default, value: summary?.bus ?? -1)
        .animation(.default, value: summary?.metro ?? -1)
    }
}

#Preview {
    NamesListView(onLogout: {})
}
