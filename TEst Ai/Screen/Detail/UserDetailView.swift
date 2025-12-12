import SwiftUI

struct UserDetailView: View {
    let user: User

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        return df
    }

    var body: some View {
        VStack(spacing: 24) {
            // Фото из ассетов, если задано для этого пользователя
            if let avatar = user.avatarImageName, !avatar.isEmpty {
                Image(avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .accessibilityLabel(Text("Аватар пользователя"))
            } else {
                // Фолбэк на системный символ, если фото не задано
                Image(systemName: user.symbolNameConsideringAge)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(user.colorConsideringAge)
                    .accessibilityLabel(Text("Иконка пользователя"))
            }

            VStack(spacing: 8) {
                Text(user.name)
                    .font(.title)
                    .bold()

                HStack {
                    Image(systemName: "calendar")
                    Text(
                        String(
                            format: NSLocalizedString("birthdate.label", comment: "Дата рождения: %@"),
                            dateFormatter.string(from: user.birthDate)
                        )
                    )
                }
                .font(.body)

                HStack {
                    Image(systemName: "person.2")
                    Text(
                        String(
                            format: NSLocalizedString("gender.label", comment: "Пол: %@"),
                            user.gender.title
                        )
                    )
                }
                .font(.body)
            }

            NavigationLink {
                TicketsView(memberID: user.id.uuidString, memberName: user.name)
            } label: {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Билеты \(user.name)")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle(NSLocalizedString("profile.title", comment: "Профиль"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        UserDetailView(user: User(
            name: "Мария",
            birthDate: Date(timeIntervalSince1970: 915148800),
            gender: .female,
            avatarImageName: "miss" // имя ассета из вашего каталога
        ))
    }
}
