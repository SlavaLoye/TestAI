//
//  MainTabView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 10.12.2025.
//

import SwiftUI

struct MainTabView: View {
    let vyacheslavID: String
    let onLogout: () -> Void

    @State private var selectedTab: Int = 0
    @State private var showPaywall: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Моя семья
            NavigationStack {
                NamesListView(onLogout: onLogout)
                    .navigationTitle(NSLocalizedString("tab.people", comment: "People"))
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text(NSLocalizedString("tab.people", comment: "People"))
            }
            .tag(0)

            // Подписка — всегда для Вячеслава
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
                TicketsView(memberID: vyacheslavID, memberName: "Вячеслав")
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
                ProfileView()
                    .navigationTitle(NSLocalizedString("tab.profile", comment: "My Profile"))
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(NSLocalizedString("logout.button.title", comment: "Выйти")) {
                                onLogout()
                            }
                        }
                    }
            }
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text(NSLocalizedString("profile.title", comment: "My Profile"))
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

#Preview {
    MainTabView(vyacheslavID: "11111111-1111-1111-1111-111111111111", onLogout: {})
}

