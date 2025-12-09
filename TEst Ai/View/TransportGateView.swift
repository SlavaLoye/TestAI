//
//  TransportGateView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 10.12.2025.
//

import SwiftUI

struct TransportGateView: View {
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
