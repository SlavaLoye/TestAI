//
//  MapGateView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 10.12.2025.
//

import SwiftUI

struct MapGateView: View {
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
