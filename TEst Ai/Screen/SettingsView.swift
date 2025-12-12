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

    // Источник пользователей из сидов (для отображения карточки «Мой аккаунт»)
    @State private var allUsers: [User] = UsersSeed.initial

    // Состояние для показа редактора профиля
    @State private var showEditProfile: Bool = false

    // Состояние для подтверждения выхода
    @State private var showLogoutConfirm: Bool = false

    // Профиль по MVVM
    @StateObject private var profileVM = ProfileViewModel()

    // Черновик редактируемых полей
    @State private var draftName: String = ""
    @State private var draftBirthDate: Date = {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }()
    @State private var draftGender: Gender = .other

    // Текущий «главный» пользователь из сидов, если присутствует
    private var primaryUserFromSeed: User? {
        guard !profileVM.primaryUserID.isEmpty,
              let uuid = UUID(uuidString: profileVM.primaryUserID) else { return nil }
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
                    // Аватарка: если есть фото — показываем, иначе SF Symbol
                    if let avatar = primaryUserFromSeed?.avatarImageName, !avatar.isEmpty {
                        Image(avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        Image(systemName: (primaryUserFromSeed?.symbolNameConsideringAge) ?? "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .foregroundStyle(primaryUserFromSeed?.colorConsideringAge ?? .gray)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Имя берем из профиля (источник правды), если не пустое, иначе fallback к сид-пользователю
                        Text(!profileVM.name.isEmpty ? profileVM.name : (primaryUserFromSeed?.name ?? "Мой аккаунт"))
                            .font(.headline)

                        // Доп. сведения: дата и пол — из профиля
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(dateFormatter.string(from: profileVM.birthDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "person.2")
                                .foregroundStyle(.secondary)
                            Text(profileVM.gender.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        prepareDraftFromProfile()
                        showEditProfile = true
                    } label: {
                        Label("Редактировать", systemImage: "square.and.pencil")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    prepareDraftFromProfile()
                    showEditProfile = true
                }
            } header: {
                Text("Мой аккаунт")
            }

            // Настройки учетной записи
            Section("Учетная запись") {
                Button(role: .destructive) {
                    showLogoutConfirm = true
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
                            saveDraftIntoProfile()
                            showEditProfile = false
                        }
                        .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(
            NSLocalizedString("logout.confirm.title", comment: "Выход"),
            isPresented: $showLogoutConfirm
        ) {
            Button(NSLocalizedString("logout.confirm.cancel", comment: "Отмена"), role: .cancel) { }
            Button(NSLocalizedString("logout.confirm.ok", comment: "Выйти"), role: .destructive) {
                onLogout()
            }
        } message: {
            Text(NSLocalizedString("logout.confirm.message", comment: "Вы действительно хотите выйти?"))
        }
        .onAppear {
            // Обеспечим дефолты и загрузим профиль
            profileVM.load()

            // Если главного нет — назначим "Вячеслава" или первого из сидов
            if profileVM.primaryUserID.isEmpty {
                if let vyacheslav = allUsers.first(where: { $0.name == "Вячеслав" }) {
                    profileVM.primaryUserID = vyacheslav.id.uuidString
                    profileVM.save()
                    legacyPrimaryUserID = vyacheslav.id.uuidString
                } else if let first = allUsers.first {
                    profileVM.primaryUserID = first.id.uuidString
                    profileVM.save()
                    legacyPrimaryUserID = first.id.uuidString
                }
            } else {
                // Однонаправленная синхронизация legacy (для совместимости)
                if legacyPrimaryUserID != profileVM.primaryUserID {
                    legacyPrimaryUserID = profileVM.primaryUserID
                }
            }
        }
    }

    private func prepareDraftFromProfile() {
        draftName = profileVM.name
        draftBirthDate = profileVM.birthDate
        draftGender = profileVM.gender
    }

    private func saveDraftIntoProfile() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        profileVM.name = trimmed
        profileVM.birthDate = draftBirthDate
        profileVM.gender = draftGender
        profileVM.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView(onLogout: {})
    }
}
