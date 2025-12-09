//
//  AddNameView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct AddNameView: View {
    @State private var name: String = ""
    @State private var birthDate: Date = {
        // По умолчанию 18 лет назад
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }()
    @State private var gender: Gender = .other

    @FocusState private var nameFocused: Bool
    let onAdd: (User) -> Void
    @Environment(\.dismiss) private var dismiss

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(NSLocalizedString("name.section.title", comment: "Имя")) {
                TextField(NSLocalizedString("name.placeholder", comment: "Введите имя"), text: $name)
                    .focused($nameFocused)
            }

            Section(NSLocalizedString("birthdate.section.title", comment: "Дата рождения")) {
                DatePicker(NSLocalizedString("birthdate.picker.title", comment: "Выберите дату"),
                           selection: $birthDate,
                           displayedComponents: .date)
            }

            Section(NSLocalizedString("gender.section.title", comment: "Пол")) {
                Picker(NSLocalizedString("gender.picker.title", comment: "Пол"), selection: $gender) {
                    ForEach(Gender.allCases) { g in
                        Text(g.title).tag(g)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button(NSLocalizedString("save.button.title", comment: "Сохранить")) {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let user = User(name: trimmed, birthDate: birthDate, gender: gender)
                    onAdd(user)
                    dismiss()
                }
                .disabled(!isNameValid)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                nameFocused = true
            }
        }
    }
}

#Preview {
    AddNameView(onAdd: { _ in })
}
