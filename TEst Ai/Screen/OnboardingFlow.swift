//
//  OnboardingFlow.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 9.12.2025.
//

import SwiftUI

struct OnboardingFlow: View {
    let onFinish: () -> Void

    @State private var page: Int = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                OnboardingPageView(
                    title: NSLocalizedString("onboarding.page1.title", comment: "Welcome"),
                    subtitle: NSLocalizedString("onboarding.page1.subtitle", comment: "Manage people, transport and home in one place."),
                    systemImage: "person.3.fill"
                )
                .tag(0)

                OnboardingPageView(
                    title: NSLocalizedString("onboarding.page2.title", comment: "Map & Location"),
                    subtitle: NSLocalizedString("onboarding.page2.subtitle", comment: "See traffic, your location and navigate faster."),
                    systemImage: "map.fill"
                )
                .tag(1)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: continueTapped) {
                Text(page == 1
                     ? NSLocalizedString("onboarding.finish", comment: "Continue")
                     : NSLocalizedString("onboarding.next", comment: "Next"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
    }

    private func continueTapped() {
        if page < 1 {
            withAnimation { page += 1 }
        } else {
            onFinish()
        }
    }
}

private struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }
}
