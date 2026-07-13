//
//  OnboardingView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

/**
 처음 시작하는 유저에게 보여지는
 온보딩 화면
 */

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @EnvironmentObject var appState: AppState

    @State private var pageNumber = 0
    @Binding var isFirstVisit: Bool

    private let onboardingItems = OnboardItem.getAll()

    var body: some View {
        ZStack {
            // 배경
            ScreenBackground()

            VStack(spacing: 0) {
                // 상단 스킵 버튼
                HStack {
                    Spacer()
                    if pageNumber < onboardingItems.count - 1 {
                        Button(action: {
                            isFirstVisit = false
                        }) {
                            Text(L.Onboarding.skip.localized)
                                .font(DS.Font.callout())
                                .foregroundColor(DS.Colors.textSecondary)
                                .padding(.horizontal, DS.Spacing.lg)
                                .padding(.vertical, DS.Spacing.xs)
                        }
                    }
                }
                .padding(.top, DS.Spacing.xxxl)

                // 메인 컨텐츠
                TabView(selection: $pageNumber) {
                    ForEach(onboardingItems.indices, id: \.self) { index in
                        GeometryReader { geo in
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: DS.Spacing.xxxl) {
                                    Spacer(minLength: DS.Spacing.lg)

                                    // 이미지 (장식용)
                                    Image(onboardingItems[index].imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: geo.size.height * 0.4)
                                        .padding(.horizontal, DS.Spacing.xxxl)
                                        .accessibilityHidden(true)

                                    // 텍스트
                                    VStack(spacing: DS.Spacing.md) {
                                        Text(getTitleForPage(index))
                                            .font(DS.Font.largeTitle())
                                            .foregroundColor(DS.Colors.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(onboardingItems[index].description.localized)
                                            .font(DS.Font.body())
                                            .foregroundColor(DS.Colors.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(6)
                                            .padding(.horizontal, DS.Spacing.xxl)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: DS.Spacing.lg)
                                }
                                .frame(minHeight: geo.size.height)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // 하단 영역
                VStack(spacing: DS.Spacing.xl) {
                    // 페이지 인디케이터 (장식용)
                    HStack(spacing: DS.Spacing.xs) {
                        ForEach(onboardingItems.indices, id: \.self) { index in
                            if pageNumber == index {
                                Capsule()
                                    .fill(DS.Colors.accent)
                                    .frame(width: 24, height: 8)
                            } else {
                                Circle()
                                    .fill(DS.Colors.separator)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .accessibilityHidden(true)

                    // 버튼
                    Button {
                        if pageNumber < onboardingItems.count - 1 {
                            withAnimation {
                                pageNumber += 1
                            }
                        } else {
                            isFirstVisit = false
                        }
                    } label: {
                        Text(pageNumber == onboardingItems.count - 1 ? L.Onboarding.start.localized : L.Onboarding.next.localized)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, DS.Spacing.xl)
                }
                .padding(.bottom, DS.Spacing.xxxl)
            }
        }
    }

    private func getTitleForPage(_ index: Int) -> String {
        switch index {
        case 0:
            return L.Onboarding.title1.localized
        case 1:
            return L.Onboarding.title2.localized
        case 2:
            return L.Onboarding.title3.localized
        case 3:
            return L.Onboarding.title4.localized
        default:
            return ""
        }
    }
}


struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isFirstVisit: .constant(true))
    }
}
