//
//  LoginView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var emailFocused: Bool
    @State private var animateIn: Bool = false

    init(onLogin: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(onLogin: onLogin))
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                    .padding(.top, 16)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.05), value: animateIn)

                formCard
                    .padding(.horizontal)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.1), value: animateIn)

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emailFocused = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                animateIn = true
            }
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.30, green: 0.64, blue: 0.96),
                Color(red: 0.18, green: 0.49, blue: 0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 88, height: 88)

                Image(systemName: "envelope.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.white.opacity(0.30))
                    .font(.system(size: 50, weight: .bold))
            }

            Text("Введите ваш адрес электронной почты, чтобы продолжить")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            emailField

            if viewModel.showInvalidEmail {
                invalidEmailRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            loginButton
        }
        .padding(20)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(.white)
                    .frame(width: 22)

                ZStack(alignment: .trailing) {
                    TextField("Введите email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($emailFocused)
                        .tint(.white)
                        .foregroundStyle(.white)

                    if !viewModel.email.isEmpty {
                        Image(systemName: viewModel.isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.isEmailValid ? .white : .white)
                            .opacity(viewModel.isEmailValid ? 0.9 : 1.0)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(emailFocused ? Color.white : Color.white.opacity(0.65), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var invalidEmailRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(.red)
            Text("Некорректный email")
                .font(.footnote)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private var loginButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                viewModel.login()
            }
        } label: {
            Text("Войти")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(loginButtonBackground)
                .foregroundStyle(loginButtonForeground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(loginButtonStrokeColor, lineWidth: 1)
                )
        }
        // Keep interaction enabled; style communicates state.
        // .disabled(!viewModel.isEmailValid)  // enable if you want strict disable
    }

    // Always return a LinearGradient to satisfy 'some ShapeStyle'
    private var loginButtonBackground: LinearGradient {
        if viewModel.isEmailValid {
            return LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.27, blue: 0.27),
                    Color(red: 0.90, green: 0.10, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white,
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var loginButtonForeground: Color {
        viewModel.isEmailValid ? .white : .black
    }

    private var loginButtonStrokeColor: Color {
        viewModel.isEmailValid ? .clear : Color.black.opacity(0.1)
    }
}

#Preview("Light") {
    LoginView(onLogin: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView(onLogin: {})
        .preferredColorScheme(.dark)
}
