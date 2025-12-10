//
//  LoginView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var emailFocused: Bool

    init(onLogin: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(onLogin: onLogin))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Вход по email")
                .font(.title2)
                .bold()

            TextField("Введите email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .focused($emailFocused)

            if viewModel.showInvalidEmail {
                Text("Некорректный email")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                viewModel.login()
            } label: {
                Text("Войти")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.isEmailValid ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.isEmailValid)

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emailFocused = true
            }
        }
    }
}

#Preview {
    LoginView(onLogin: {})
}
