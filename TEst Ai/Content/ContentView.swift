//
//  ContentView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI

struct ContentView: View {
    // Сохраняем флаг входа между запусками
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        if isLoggedIn {
            TabView {
                // 1. Подписки — первая вкладка
                NavigationStack {
                    PaywallView()
                        .navigationTitle("Подписки")
                }
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Подписки")
                }

                // 2. Моя семья — бывшая "Моя семья "
                NavigationStack {
                    NamesListView(onLogout: { isLoggedIn = false })
                        .navigationTitle("Моя семья")
                }
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Моя семья")
                }

                // 3. Дом
                NavigationStack {
                    HomeView()
                        .navigationTitle("Дом")
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Дом")
                }

                // 4. Настройки
                NavigationStack {
                    SettingsView(onLogout: { isLoggedIn = false })
                        .navigationTitle("Настройки")
                }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
            }
        } else {
            NavigationStack {
                LoginView(onLogin: { isLoggedIn = true })
                    .navigationTitle("Вход")
            }
        }
    }
}

#Preview {
    ContentView()
}
