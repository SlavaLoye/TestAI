//
//  AppRootView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

extension Notification.Name {
    static let subscriptionChanged = Notification.Name("subscriptionChanged")
}

struct AppRootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding: Bool = false

    // Зеркало старого ключа (оставляем только для совместимости UI, без обратной записи)
    @AppStorage("primaryUserID") private var legacyPrimaryUserID: String?

    // Глобальный флаг больше не используем для логики, оставлен для обратной совместимости
    @AppStorage("isSubscribed") private var legacyIsSubscribed: Bool = false

    // Фиксированный UUID Вячеслава из сидов
    private let userAccauntID = "11111111-1111-1111-1111-111111111111"

    var body: some View {
        Group {
            if !isLoggedIn {
                NavigationStack {
                    LoginView(onLogin: { isLoggedIn = true })
                        .navigationTitle(NSLocalizedString("login.title", comment: "Sign in with Email"))
                }
            } else if !didFinishOnboarding {
                OnboardingFlow(onFinish: { didFinishOnboarding = true })
            } else {
                MainTabView(
                    vyacheslavID: userAccauntID,
                    onLogout: {
                        isLoggedIn = false
                        didFinishOnboarding = false
                    }
                )
            }
        }
        .onAppear {
            // Базовые значения профиля
            ProfileStore.ensureDefaultProfile()

            // Зафиксировать главного пользователя на Вячеслава
            if ProfileStore.primaryUserID != userAccauntID {
                ProfileStore.primaryUserID = userAccauntID
            }

            // Однонаправленная синхронизация legacy (для старых экранов/ключей)
            if legacyPrimaryUserID != userAccauntID {
                legacyPrimaryUserID = userAccauntID
            }
        }
        // Важно: убираем обратную синхронизацию legacy -> ProfileStore,
        // чтобы никто не мог случайно сменить главного.
    }
}

#Preview {
    AppRootView()
}
