//
//  LoginView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @FocusState private var emailFocused: Bool
    @State private var showInvalidEmail: Bool = false

    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Вход по email")
                .font(.title2)
                .bold()

            TextField("Введите email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .focused($emailFocused)

            if showInvalidEmail {
                Text("Некорректный email")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: loginTapped) {
                Text("Войти")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isEmailValid ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(!isEmailValid)

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emailFocused = true
            }
        }
    }

    private var isEmailValid: Bool {
        // Простая валидация email через регулярку
        
        let pattern =
        #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let pred = NSPredicate(format: "SELF MATCHES[c] %@", pattern)
        return pred.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func loginTapped() {
        let valid = isEmailValid
        showInvalidEmail = !valid
        if valid {
            onLogin()
        }
    }
}

#Preview {
    LoginView(onLogin: {})
}
