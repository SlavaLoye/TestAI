import SwiftUI

struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String?
    let systemImage: String?
    let color: Color

    init(title: String, subtitle: String, imageName: String? = nil, systemImage: String? = nil, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.systemImage = systemImage
        self.color = color
    }
}

struct OnboardingView: View {
    let pages: [OnboardingPage]
    let onFinish: () -> Void
    @State private var index: Int = 0

    var body: some View {
        VStack {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element) { idx, p in
                    VStack(spacing: 0) {
                        // Card with colored wave header
                        VStack(spacing: 16) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(p.color.opacity(0.12))
                                    .frame(height: 220)
                                    .overlay(
                                        // Page image centered within the card header
                                        Group {
                                            switch idx {
                                            case 0:
                                                Image("onboardin1")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxHeight: 200)
                                            case 1:
                                                Image("onboardin2")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxHeight: 200)
                                            default:
                                                Image("onboardin3")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxHeight: 200)
                                            }
                                        }
                                        .padding(16)
                                    )
                                    .shadow(color: p.color.opacity(0.18), radius: 16, x: 0, y: 10)

                                // Small decorative dots
                                HStack(spacing: 8) {
                                    Circle().fill(.white.opacity(0.35)).frame(width: 10, height: 10)
                                    Circle().fill(.white.opacity(0.25)).frame(width: 6, height: 6)
                                    Circle().fill(.white.opacity(0.2)).frame(width: 4, height: 4)
                                }
                                .padding(.leading, 16)
                                .padding(.top, 16)
                            }

                            VStack(spacing: 10) {
                                Text(p.title)
                                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(p.subtitle)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Decorative chips/rows
                            VStack(spacing: 10) {
                                switch idx {
                                case 0: // Добро пожаловать
                                    OnboardingChip(color: p.color, intensity: 0.15, leadingIcon: "bolt.fill", title: "Быстрый старт", trailingIcon: "chevron.right.circle.fill")
                                    OnboardingChip(color: p.color, intensity: 0.12, leadingIcon: "square.stack.3d.up.fill", title: "Единый доступ", trailingIcon: "plus.circle.fill")
                                    OnboardingChip(color: p.color, intensity: 0.10, leadingIcon: "person.2.fill", title: "Синхронизация семьи", trailingIcon: nil)
                                case 1: // Моя семья
                                    OnboardingChip(color: p.color, intensity: 0.15, leadingIcon: "person.3.fill", title: "Профили членов семьи", trailingIcon: "chevron.right.circle.fill")
                                    OnboardingChip(color: p.color, intensity: 0.12, leadingIcon: "bell.badge.fill", title: "Общие напоминания", trailingIcon: nil)
                                    OnboardingChip(color: p.color, intensity: 0.10, leadingIcon: "checkmark.shield.fill", title: "Роли и права", trailingIcon: nil)
                                default: // Карта и геолокация/маршруты
                                    OnboardingChip(color: p.color, intensity: 0.15, leadingIcon: "car.fill", title: "Онлайн‑трафик", trailingIcon: nil)
                                    OnboardingChip(color: p.color, intensity: 0.12, leadingIcon: "map.fill", title: "Маршруты быстрее", trailingIcon: "chevron.right.circle.fill")
                                    OnboardingChip(color: p.color, intensity: 0.10, leadingIcon: "mappin.circle.fill", title: "Метки мест", trailingIcon: nil)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer(minLength: 0)
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: continueTapped) {
                Text(index == pages.count - 1
                     ? NSLocalizedString("onboarding.finish", comment: "Continue")
                     : NSLocalizedString("onboarding.next", comment: "Next"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(pages[safe: index]?.color ?? Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
    }

    private func continueTapped() {
        if index < pages.count - 1 {
            withAnimation { index += 1 }
        } else {
            onFinish()
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

fileprivate struct WaveHeader: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Left colored block with a smooth wave to the right
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: w * 0.58, y: 0))
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h),
            control1: CGPoint(x: w * 0.70, y: h * 0.35),
            control2: CGPoint(x: w * 0.46, y: h * 0.65)
        )
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

fileprivate struct OnboardingChip: View {
    let color: Color
    let intensity: CGFloat
    let leadingIcon: String
    let title: String
    let trailingIcon: String?

    var body: some View {
        Capsule()
            .fill(color.opacity(intensity))
            .frame(height: 48)
            .overlay(
                HStack(spacing: 12) {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(color.opacity(0.85))
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    if let trailingIcon {
                        Image(systemName: trailingIcon)
                            .foregroundStyle(color)
                    }
                }
                .padding(.horizontal, 14)
            )
    }
}

