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
                ForEach(vm.filteredUsers) { user in
                    NavigationLink {
                        UserDetailView(user: user)
                    } label: {
                        HStack(spacing: 8) {
                            // Метка главного пользователя
                            if vm.isPrimary(user) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }

                            Image(systemName: user.symbolNameConsideringAge)
                                .foregroundStyle(user.colorConsideringAge)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(vm.isPrimary(user) ? .headline : .body)

                                // Подзаголовок с билетами: "<Title> — <count>, <Title> — <count>"
                                if let summary = vm.ticketSummary[user.id] {
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
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if vm.isPrimary(user) {
                            // Запрещаем удаление главного — не показываем destructive кнопку
                            Button {
                                // Ничего: можно подсветить, что это главный
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
                    .onAppear {
                        // Обновим сводку для пользователя при появлении строки
                        vm.refreshSummary(for: user)
                    }
                }
                .onDelete(perform: vm.delete)
            }
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

#Preview {
    NamesListView(onLogout: {})
}
