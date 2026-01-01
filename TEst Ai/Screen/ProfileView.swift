import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var avatarImage: Image? = Image(systemName: "person.circle.fill")
    @State private var isEditingProfile: Bool = false
    @State private var notificationsEnabled: Bool = true
    @State private var showPhotoPicker: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var userChangedAvatar: Bool = false
    @State private var allUsers: [User] = UsersSeed.initial

    @AppStorage("profile.name") private var storedName: String = "Иван Иванов"
    @AppStorage("profile.email") private var storedEmail: String = "user@example.com"
    @AppStorage("profile.dob") private var storedDOB: String = ""

    private var primaryUserFromSeed: User? {
        guard let uuid = UUID(uuidString: ProfileStore.primaryUserID) else { return nil }
        return allUsers.first { $0.id == uuid }
    }

    private func loadDefaultAvatarIfNeeded() {
        // Не перезаписываем, если пользователь уже выбрал своё фото
        guard !userChangedAvatar else { return }
        if let u = primaryUserFromSeed, let asset = u.avatarImageName, !asset.isEmpty {
            avatarImage = Image(asset)
        } else {
            avatarImage = Image(systemName: "person.crop.circle.fill")
        }
    }

    var body: some View {
        List {
            // Фото и Имя (одна секция)
            Section("Фото и имя") {
                HStack(spacing: 16) {
                    avatarImage?
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(storedName.isEmpty ? "Не указано" : storedName)
                            .font(.headline)
                        if !storedEmail.isEmpty {
                            Text(storedEmail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Изменить фото", systemImage: "camera.fill")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            avatarImage = Image(systemName: "person.circle.fill")
                        } label: {
                            Label("Сбросить фото", systemImage: "trash")
                        }
                    }
                }
            }

            // Дата рождения
            Section("Дата рождения") {
                HStack {
                    Text(storedDOB.isEmpty ? "Не указано" : storedDOB)
                        .foregroundStyle(storedDOB.isEmpty ? .secondary : .primary)
                    Spacer()
                    NavigationLink {
                        DOBEditView(dob: $storedDOB)
                            .navigationTitle("Дата рождения")
                    } label: {
                        Label("Указать / изменить", systemImage: "calendar")
                    }
                }
            }

            // Профиль (редактировать)
            Section("Профиль") {
                Button {
                    isEditingProfile = true
                } label: {
                    Label("Редактировать профиль", systemImage: "pencil")
                }
            }

            // Выход
            Section {
                Button(role: .destructive) {
                    // handle logout
                } label: {
                    Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            // О приложении
            Section("О приложении") {
                NavigationLink {
                    AboutAppView()
                        .navigationTitle("О приложении")
                } label: {
                    Label("Информация", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Профиль")
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                    userChangedAvatar = true
                }
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(name: $storedName, email: $storedEmail)
        }
        .onAppear {
            // Синхронизируем имя и email из центрального профиля
            storedName = ProfileStore.name
            storedEmail = ProfileStore.email
            // Загружаем дефолтный аватар для текущего главного пользователя
            loadDefaultAvatarIfNeeded()
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var email: String
    @State private var draftName: String = ""
    @State private var draftEmail: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Имя", text: $draftName)
                    TextField("Email", text: $draftEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Редактировать")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        name = draftName
                        email = draftEmail
                        dismiss()
                    }
                }
            }
            .onAppear {
                draftName = name
                draftEmail = email
            }
        }
    }
}

struct DOBEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dob: String
    @State private var draftDOB: Date = Date()

    var body: some View {
        Form {
            DatePicker("Дата рождения", selection: $draftDOB, displayedComponents: .date)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.locale = Locale.current
                    dob = formatter.string(from: draftDOB)
                    dismiss()
                }
            }
        }
        .onAppear {
            if !dob.isEmpty {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.locale = Locale.current
                if let parsed = formatter.date(from: dob) {
                    draftDOB = parsed
                }
            }
        }
    }
}

struct AboutAppView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("TEst Ai")
                .font(.title2).bold()
            Text("Версия 1.0")
                .foregroundStyle(.secondary)
            Text("Это демо-страница о приложении. Здесь можно разместить лицензионную информацию, ссылки и т.д.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
