//
//  OnboardingView.swift
//  Dalbit
//
//  첫 실행 안내 — **왜 이 앱인가**만 말한다.
//
//  ⚠️ 조작법(탭·좌우·위·아래)은 여기서 설명하지 않는다. 그건 홈에서 달을 눈앞에 두고
//     `GestureCoachmark` 가 알려 준다. 같은 내용을 두 번 말하면 둘 다 흘려 듣게 되고,
//     맥락 없이 먼저 읽은 조작법은 어차피 기억에 남지 않는다.
//     여기(왜) → 코치마크(어떻게) 순서가 이 화면이 지키는 유일한 규칙이다.
//
//  ⚠️ 언제든 건너뛸 수 있어야 한다. 잠들려고 앱을 연 사람에게 네 장을 강제로 넘기게 하면
//     그 자체가 이 앱이 없애려던 "잠들기 전에 낭비하는 시간"이 된다.
//

import SwiftUI

struct OnboardingView: View {

    /// 닫힘(완료 또는 건너뛰기). 저장은 호출부가 한다 — 이 화면은 표시만 맡는다.
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page: Identifiable {
        let id: Int
        let titleKey: String
        let bodyKey: String
    }

    private let pages: [Page] = [
        Page(id: 0, titleKey: L.Onboarding.Page1.title, bodyKey: L.Onboarding.Page1.body),
        Page(id: 1, titleKey: L.Onboarding.Page2.title, bodyKey: L.Onboarding.Page2.body),
        Page(id: 2, titleKey: L.Onboarding.Page3.title, bodyKey: L.Onboarding.Page3.body),
        Page(id: 3, titleKey: L.Onboarding.Page4.title, bodyKey: L.Onboarding.Page4.body)
    ]

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: 0) {
                skipRow()

                TabView(selection: $page) {
                    ForEach(pages) { item in
                        pageBody(item).tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                indicator()
                    .padding(.bottom, DS.Spacing.lg)

                Button {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
                    }
                } label: {
                    Text(isLast ? L.Onboarding.start.localized : L.Onboarding.next.localized)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.xxl)
            }
            .dsConstrainedWidth()
        }
    }

    // MARK: - 조각들

    @ViewBuilder
    private func skipRow() -> some View {
        HStack {
            Spacer()
            // 마지막 장에서는 숨긴다 — 바로 아래에 「시작하기」가 있어서 둘이 같은 말이 된다.
            if !isLast {
                Button(action: onFinish) {
                    Text(L.Onboarding.skip.localized)
                        .font(DS.Font.callout())
                        .foregroundColor(DS.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, DS.Spacing.screen)
    }

    @ViewBuilder
    private func pageBody(_ item: Page) -> some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer(minLength: 0)

            // 표식은 홈의 달과 같은 언어로 — 첫 화면에서 본 것이 홈에서 그대로 이어져야 한다.
            CrescentGlyph(size: 132)

            VStack(spacing: DS.Spacing.md) {
                Text(item.titleKey.localized)
                    .font(DS.Font.title())
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.bodyKey.localized)
                    .font(DS.Font.callout())
                    .foregroundColor(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Spacing.xxl)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func indicator() -> some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(pages) { item in
                Capsule()
                    .fill(item.id == page ? DS.Colors.accent : DS.Colors.textTertiary.opacity(0.35))
                    .frame(width: item.id == page ? 20 : 6, height: 6)
                    .animation(.easeOut(duration: 0.25), value: page)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onFinish: {})
    }
}
