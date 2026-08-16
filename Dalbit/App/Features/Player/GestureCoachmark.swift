//
//  GestureCoachmark.swift
//  Dalbit
//
//  첫 실행 1회 제스처 안내 오버레이 (탭·좌우·위·아래).
//

import SwiftUI

struct GestureCoachmark: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: DS.Spacing.lg) {
                Text(L.Listen.Coachmark.title.localized)
                    .font(DS.Font.title())
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    row("hand.tap.fill", L.Listen.Coachmark.tap.localized)
                    row("arrow.left.and.right", L.Listen.Coachmark.swipeSide.localized)
                    row("arrow.up", L.Listen.Coachmark.swipeUp.localized)
                    row("arrow.down", L.Listen.Coachmark.swipeDown.localized)
                }

                Button(action: onDismiss) {
                    Text(L.Onboarding.start.localized)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Colors.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(Capsule().fill(DS.Colors.accent))
                }
                .padding(.top, DS.Spacing.xs)
            }
            .padding(DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, DS.Spacing.xl)
        }
    }

    @ViewBuilder
    private func row(_ icon: String, _ text: String) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DS.Colors.accent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.12)))
            Text(text)
                .font(DS.Font.callout())
                .foregroundColor(.white)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Starfield (우주를 여행하듯 천천히 흐르는 별)

/// 배경 별. 좌우로는 흐르지 않고 "위로 올라감 / 아래로 내려감 / 앞으로 나아감(줌)"
/// 세 가지 방향을 약 5분에 한 번씩만 천천히 전환한다. 달이 우주를 떠다니는 느낌.
// MARK: - Cosmic Events (우주 여행 앰비언트)

/// 가끔 밤하늘을 지나가는 우주 여행 이벤트 — 혜성·먼 행성·우주선.
/// 별밭 위, 달 뒤 레이어에서 낮은 빈도로 나타나 은은하게 지나간다.
/// 위성과 같은 TimelineView 시간 기반 — 위치·페이드·점멸을 매 프레임 계산한다.
