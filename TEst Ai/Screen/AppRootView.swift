//
//  ContentView.swift
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

    @State private var showPaywall: Bool = false
    @State private var selectedTab: Int = 0

    // Фиксированный UUID Вячеслава из сидов
    private let vyacheslavID = "11111111-1111-1111-1111-111111111111"

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
                TabView(selection: $selectedTab) {
                    // Моя семья
                    NavigationStack {
                        NamesListView(onLogout: {
                            isLoggedIn = false
                            didFinishOnboarding = false
                        })
                        .navigationTitle(NSLocalizedString("tab.people", comment: "People"))
                    }
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text(NSLocalizedString("tab.people", comment: "People"))
                    }
                    .tag(0)

                    // Подписка/Транспорт — всегда для Вячеслава
                    NavigationStack {
                        TransportGateView(memberID: vyacheslavID, selection: $selectedTab)
                            .navigationTitle(NSLocalizedString("transport.title", comment: "Transport"))
                    }
                    .tabItem {
                        Image(systemName: "creditcard.fill")
                        Text(NSLocalizedString("tab.transport", comment: "Subscriptions"))
                    }
                    .tag(1)

                    // Мои билеты — показываем билеты Вячеслава (главного)
                    NavigationStack {
                        TicketsView(memberID: vyacheslavID,
                                    memberName: "Вячеслав")
                            .navigationTitle("Мои билеты")
                    }
                    .tabItem {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Билеты")
                    }
                    .tag(2)

                    // Карта — доступ по подписке Вячеслава
                    NavigationStack {
                        MapGateView(memberID: vyacheslavID, selection: $selectedTab)
                            .navigationTitle(NSLocalizedString("transport.title", comment: "Transport"))
                    }
                    .tabItem {
                        Image(systemName: "map.fill")
                        Text(NSLocalizedString("tab.map", comment: "Map"))
                    }
                    .tag(3)

                    // Профиль
                    NavigationStack {
                        SettingsView(onLogout: {
                            isLoggedIn = false
                            didFinishOnboarding = false
                        })
                        .navigationTitle(NSLocalizedString("tab.profile", comment: "My Profile"))
                    }
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text(NSLocalizedString("tab.profile", comment: "My Profile"))
                    }
                    .tag(4)
                }
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 1 && !SubscriptionStore.isSubscribed(memberID: vyacheslavID) {
                        showPaywall = true
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
            }
        }
        .onAppear {
            // Базовые значения профиля
            ProfileStore.ensureDefaultProfile()

            // Зафиксировать главного пользователя на Вячеслава
            if ProfileStore.primaryUserID != vyacheslavID {
                ProfileStore.primaryUserID = vyacheslavID
            }

            // Однонаправленная синхронизация legacy (для старых экранов/ключей)
            if legacyPrimaryUserID != vyacheslavID {
                legacyPrimaryUserID = vyacheslavID
            }
        }
        // Важно: убираем обратную синхронизацию legacy -> ProfileStore,
        // чтобы никто не мог случайно сменить главного.
    }
}

private struct TransportGateView: View {
    let memberID: String
    @Binding var selection: Int
    @State private var isSubscribed: Bool = false
    @State private var showPaywall: Bool = false

    init(memberID: String, selection: Binding<Int>) {
        self.memberID = memberID
        self._selection = selection
    }

    var body: some View {
        Group {
            if isSubscribed {
                ZStack {
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.blue.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.green.opacity(0.25), Color.green.opacity(0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 140, height: 140)
                                .shadow(color: .green.opacity(0.25), radius: 20, x: 0, y: 10)

                            Image(systemName: "checkmark.seal.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white, Color.green)
                                .font(.system(size: 72, weight: .bold))
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        }

                        Text("Ваша подписка оформлена")
                            .font(.title.bold())
                            .multilineTextAlignment(.center)

                        Text("Теперь доступны транспорт, трафик и маршруты")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            selection = 3
                        } label: {
                            Text("Открыть карту")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.top, 8)
                        .padding(.horizontal)

                        Spacer(minLength: 0)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "bus")
                        .font(.system(size: 48))
                        .foregroundStyle(.background)
                    Text("Доступ к маршрутам и билетам")
                        .font(.headline)
                    Text("Оформите подписку, чтобы открыть транспорт, трафик и маршруты.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Оформить подписку") {
                        showPaywall = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
            }
        }
        .onAppear {
            isSubscribed = SubscriptionStore.isSubscribed(memberID: memberID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionChanged)) { _ in
            isSubscribed = SubscriptionStore.isSubscribed(memberID: memberID)
        }
    }
}

private struct MapGateView: View {
    let memberID: String
    @Binding var selection: Int
    @State private var isSubscribed: Bool = false

    var body: some View {
        Group {
            if isSubscribed {
                TransportView()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)
                    Text("Доступ к карте доступен по подписке")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Оформите подписку, чтобы открыть транспорт, трафик и маршруты.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        selection = 1
                    } label: {
                        Text("Оформить подписку")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .onAppear {
            isSubscribed = SubscriptionStore.isSubscribed(memberID: memberID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionChanged)) { _ in
            isSubscribed = SubscriptionStore.isSubscribed(memberID: memberID)
        }
    }
}

#Preview {
    AppRootView()
}
