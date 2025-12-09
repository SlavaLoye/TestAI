//
//  PaywallView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 9.12.2025.
//

import SwiftUI

// MARK: - Хранилище подписки на основе UserDefaults
enum SubscriptionStore {
    private static let keyGlobal = "subscription.isSubscribed"
    private static var defaults: UserDefaults { .standard }

    // Глобальный флаг (оставляем для совместимости, но не используем далее)
    static var isSubscribed: Bool {
        get { defaults.bool(forKey: keyGlobal) }
        set { defaults.set(newValue, forKey: keyGlobal) }
    }

    static func reset() {
        defaults.removeObject(forKey: keyGlobal)
    }

    // MARK: - Персонифицированные ключи
    private static func keySubscribed(for memberID: String) -> String {
        "subscription.isSubscribed.member.\(memberID)"
    }
    private static func keyPlan(for memberID: String) -> String {
        "subscription.plan.member.\(memberID)" // SubscriptionPlan.rawValue
    }
    private static func keyActivation(for memberID: String) -> String {
        "subscription.activation.member.\(memberID)" // TimeInterval
    }

    // MARK: - Персонифицированная подписка
    static func isSubscribed(memberID: String) -> Bool {
        defaults.bool(forKey: keySubscribed(for: memberID))
    }

    static func setSubscribed(_ value: Bool, memberID: String) {
        defaults.set(value, forKey: keySubscribed(for: memberID))
    }

    static func reset(memberID: String) {
        defaults.removeObject(forKey: keySubscribed(for: memberID))
        defaults.removeObject(forKey: keyPlan(for: memberID))
        defaults.removeObject(forKey: keyActivation(for: memberID))
    }

    // MARK: - План и дата активации
    static func plan(for memberID: String) -> SubscriptionPlan? {
        guard let raw = defaults.string(forKey: keyPlan(for: memberID)) else { return nil }
        return SubscriptionPlan(rawValue: raw)
    }

    static func setPlan(_ plan: SubscriptionPlan, memberID: String) {
        defaults.set(plan.rawValue, forKey: keyPlan(for: memberID))
    }

    static func activationDate(for memberID: String) -> Date? {
        guard let ti = defaults.object(forKey: keyActivation(for: memberID)) as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: ti)
    }

    static func setActivationDate(_ date: Date, memberID: String) {
        defaults.set(date.timeIntervalSince1970, forKey: keyActivation(for: memberID))
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "Месяц"
        case .yearly: return "Год"
        }
    }

    var price: String {
        // Демо-цены
        switch self {
        case .monthly: return "199 ₽/мес"
        case .yearly: return "1490 ₽/год"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Отменить можно в любой момент"
        case .yearly: return "Скидка 38% vs месяц"
        }
    }

    var badge: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Выгодно"
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    // Локальное состояние экрана
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isProcessing: Bool = false

    // Персональная подписка для текущего главного пользователя
    private var memberID: String { ProfileStore.primaryUserID }
    @State private var isSubscribedForMember: Bool = false
    @State private var currentPlan: SubscriptionPlan?
    @State private var activationDate: Date?

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        return df
    }

    var body: some View {
        VStack(spacing: 16) {
            // Иллюстрация
            VStack(spacing: 8) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.background)
                Text("Подписка на автобус и маршруты")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text("Откройте доступ к картам трафика, маршрутам и билетам.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)

            if isSubscribedForMember {
                // Уже есть подписка — показываем статус
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("Ваша подписка оформлена")
                        .font(.headline)

                    if let plan = currentPlan {
                        Text("План: \(plan.title)")
                            .font(.subheadline)
                    }
                    if let date = activationDate {
                        Text("Активна с: \(dateFormatter.string(from: date))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                Button("Готово") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            } else {
                // Предложение оформить
                VStack(spacing: 12) {
                    planRow(.monthly, isSelected: selectedPlan == .monthly)
                        .onTapGesture { selectedPlan = .monthly }

                    planRow(.yearly, isSelected: selectedPlan == .yearly)
                        .onTapGesture { selectedPlan = .yearly }
                }
                .padding(.horizontal)

                Button(action: continueTapped) {
                    HStack {
                        Spacer()
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Продолжить").bold()
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(isProcessing ? Color.accentColor.opacity(0.7) : Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isProcessing)

                Button("Восстановить покупки") {
                    // Эмуляция восстановления
                    activate(plan: .yearly, asRestore: true)
                }
                .font(.footnote)
                .padding(.bottom, 8)

                Text("Это демонстрационный экран. Оплата не выполняется.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer(minLength: 0)
        }
        .padding(.top)
        .presentationDetents([.medium, .large])
        .onAppear {
            // Синхронизируем локальное состояние для текущего пользователя
            isSubscribedForMember = SubscriptionStore.isSubscribed(memberID: memberID)
            currentPlan = SubscriptionStore.plan(for: memberID)
            activationDate = SubscriptionStore.activationDate(for: memberID)
        }
    }

    @ViewBuilder
    private func planRow(_ plan: SubscriptionPlan, isSelected: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                    .frame(width: 28, height: 28)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.title).font(.headline)
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                Text(plan.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(plan.price)
                .font(.subheadline.bold())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func continueTapped() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            activate(plan: selectedPlan, asRestore: false)
        }
    }

    private func activate(plan: SubscriptionPlan, asRestore: Bool) {
        SubscriptionStore.setSubscribed(true, memberID: memberID)
        SubscriptionStore.setPlan(plan, memberID: memberID)
        let now = Date()
        SubscriptionStore.setActivationDate(now, memberID: memberID)

        // Сообщаем всем экранам, что подписка изменилась (для мгновенного UI-обновления)
        NotificationCenter.default.post(name: .subscriptionChanged, object: nil)

        // Обновим UI локально
        isSubscribedForMember = true
        currentPlan = plan
        activationDate = now

        if asRestore {
            dismiss()
        } else {
            isProcessing = false
            dismiss()
        }
    }
}

#Preview {
    PaywallView()
}
