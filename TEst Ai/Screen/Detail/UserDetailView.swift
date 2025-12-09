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
            Image(systemName: user.gender.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(user.gender == .female ? .pink : .blue)

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
        UserDetailView(user: User(name: "Мария",
                                  birthDate: Date(timeIntervalSince1970: 567993600),
                                  gender: .female))
    }
}
