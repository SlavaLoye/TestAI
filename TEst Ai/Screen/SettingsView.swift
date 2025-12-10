//
//  SettingsView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct SettingsView: View {
    let onLogout: () -> Void

    // Зеркало старого ключа для совместимости
    @AppStorage("primaryUserID") private var legacyPrimaryUserID: String?

    // Источник пользователей. Замените на ваше хранилище при необходимости.
    @State private var allUsers: [User] = UsersSeed.initial

    // Состояние для показа редактора профиля
    @State private var showEditProfile: Bool = false

    // Черновик редактируемых полей
    @State private var draftName: String = ""
    @State private var draftBirthDate: Date = {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }()
    @State private var draftGender: Gender = .other

    private var primaryUser: User? {
        guard !ProfileStore.primaryUserID.isEmpty,
              let uuid = UUID(uuidString: ProfileStore.primaryUserID) else { return nil }
        return allUsers.first(where: { $0.id == uuid })
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        return df
    }

    var body: some View {
        Form {
            // Блок «Мой аккаунт»
            Section {
                HStack(alignment: .center, spacing: 16) {
                    // Аватарка (иконка по полу и возрасту)
                    Image(systemName: (primaryUser?.symbolNameConsideringAge) ?? "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(primaryUser?.colorConsideringAge ?? .gray)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(primaryUser?.name ?? "Мой аккаунт")
                            .font(.headline)

                        if let user = primaryUser {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                Text(dateFormatter.string(from: user.birthDate))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "person.2")
                                    .foregroundStyle(.secondary)
                                Text(user.gender.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Выберите главного пользователя в «Моя семья»")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        prepareDraftFromPrimary()
                        showEditProfile = true
                    } label: {
                        Label("Редактировать", systemImage: "square.and.pencil")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline) // немного меньше шрифт
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6) // компактнее по высоте
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain) // кастомный вид без системного отступа
                    .contentShape(Rectangle())
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    prepareDraftFromPrimary()
                    showEditProfile = true
                }
            } header: {
                Text("Мой аккаунт")
            }

            // Настройки учетной записи
            Section("Учетная запись") {
                Button(role: .destructive) {
                    onLogout()
                } label: {
                    Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            // О приложении
            Section("О приложении") {
                HStack {
                    Text("Версия")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(NSLocalizedString("profile.title", comment: "My Profile"))
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                Form {
                    Section("Имя") {
                        TextField("Введите имя", text: $draftName)
                            .textInputAutocapitalization(.words)
                    }
                    Section("Дата рождения") {
                        DatePicker("Выберите дату", selection: $draftBirthDate, displayedComponents: .date)
                    }
                    Section("Пол") {
                        Picker("Пол", selection: $draftGender) {
                            ForEach(Gender.allCases) { g in
                                Text(g.title).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .navigationTitle("Редактировать профиль")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { showEditProfile = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сохранить") {
                            saveDraftIntoPrimary()
                            showEditProfile = false
                        }
                        .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            // Если главного нет — назначим "Вячеслава" или первого
            if ProfileStore.primaryUserID.isEmpty {
                if let vyacheslav = allUsers.first(where: { $0.name == "Вячеслав" }) {
                    ProfileStore.primaryUserID = vyacheslav.id.uuidString
                    legacyPrimaryUserID = vyacheslav.id.uuidString
                } else if let first = allUsers.first {
                    ProfileStore.primaryUserID = first.id.uuidString
                    legacyPrimaryUserID = first.id.uuidString
                }
            } else {
                // Синхронизируем зеркало старого ключа
                if legacyPrimaryUserID != ProfileStore.primaryUserID {
                    legacyPrimaryUserID = ProfileStore.primaryUserID
                }
            }
        }
    }

    private func prepareDraftFromPrimary() {
        if let user = primaryUser {
            draftName = user.name
            draftBirthDate = user.birthDate
            draftGender = user.gender
        } else {
            draftName = ""
            draftBirthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
            draftGender = .other
        }
    }

    private func saveDraftIntoPrimary() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if var user = primaryUser {
            user.name = trimmed
            user.birthDate = draftBirthDate
            user.gender = draftGender
            // Обновим в массиве
            if let idx = allUsers.firstIndex(where: { $0.id == user.id }) {
                allUsers[idx] = user
            }
        } else {
            // Если главного нет — создадим нового и назначим
            let newUser = User(name: trimmed, birthDate: draftBirthDate, gender: draftGender)
            allUsers.append(newUser)
            ProfileStore.primaryUserID = newUser.id.uuidString
            legacyPrimaryUserID = newUser.id.uuidString
        }
        // В реальном приложении здесь сохраните в ваше хранилище
    }

    private func colorForGender(_ gender: Gender?) -> Color {
        switch gender {
        case .some(.female): return .pink
        case .some(.male): return .blue
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(onLogout: {})
    }
}
