//
//  OnboardingFlow.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 9.12.2025.
//

import SwiftUI

struct OnboardingFlow: View {
    let onFinish: () -> Void

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: NSLocalizedString("onboarding.page1.title", comment: "Welcome"),
                subtitle: NSLocalizedString("onboarding.page1.subtitle", comment: "Manage people, transport and home in one place."),
                systemImage: "sparkles",
                color: BrandColors.primaryBlue
            ),
            OnboardingPage(
                title: NSLocalizedString("onboarding.page2.title", comment: "My Family"),
                subtitle: NSLocalizedString("onboarding.page2.subtitle", comment: "Create family profiles for a personalized experience."),
                systemImage: "person.3.fill",
                color: BrandColors.secondaryGreen
            ),
            OnboardingPage(
                title: NSLocalizedString("onboarding.page3.title", comment: "Map & Routes"),
                subtitle: NSLocalizedString("onboarding.page3.subtitle", comment: "See traffic, your location and navigate faster."),
                systemImage: "map.fill",
                color: BrandColors.accentRed
            )
        ]
    }

    var body: some View {
        OnboardingView(pages: pages, onFinish: onFinish)
    }
}

#Preview("Onboarding Flow") {
    OnboardingFlow(onFinish: {})
}
