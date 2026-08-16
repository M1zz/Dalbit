//
//  ListeningRecapView.swift
//  Dalbit
//
//  사용자가 **자기** 청취 기록을 보는 화면 (설정 → 나의 기록).
//  개발자 통계(UsageStatsView)와 짝이지만 보는 사람도 데이터 출처도 다르다.
//
//   개발자 통계 — 허브(CloudKit)에서 읽은 **모든 설치**의 익명 집계. 숨겨진 화면.
//   나의 기록   — 이 기기의 ListeningTracker 원장. 네트워크를 타지 않는다.
//
//  ⚠️ 여기서 **새로운 수집을 하지 않는다.** 이미 로컬에 쌓고 있는 값을 보여줄 뿐이다.
//     화면을 만들면서 "이것도 보내면 좋겠다"가 떠오르면, 그건 별도 판단으로 미룰 것.
//  ⚠️ "잠든 것 같은 밤"은 **추정**이다(타이머 완주 + 30분 이상 방치 종료). 사용자에게
//     보이는 화면이므로 단정하지 않는다 — 화면 안에 추정이라고 적어 둔다.
//     이 앱은 수면을 측정하지 않으며, 그렇게 읽히면 건강 앱으로 오해받는다.
//

import SwiftUI
import LeeoKit

struct ListeningRecapView: View {

    /// 화면에 들어온 시점의 값으로 고정한다 — 보는 도중에 숫자가 바뀌면 읽기 어렵다.
    /// (재생 중에 이 화면을 열어 둘 수 있다.)
    @State private var tracker = Snapshot()

    @State private var showFeedback = false

    /// 원장에서 한 번에 떠 온 값. ListeningTracker 를 직접 들고 있지 않은 이유는 위 주석 참고.
    private struct Snapshot {
        var totalSeconds: Double = 0
        var sessionCount: Int = 0
        var sleepLikelyCount: Int = 0
        var nightSessionCount: Int = 0
        var longestSessionSeconds: Double = 0
        var activeDayCount: Int = 0
        var streak: Int = 0

        /// 한 번도 안 들었으면 빈 화면을 보여준다.
        var isEmpty: Bool { sessionCount == 0 && totalSeconds == 0 }

        static func current() -> Snapshot {
            let t = ListeningTracker.shared
            return Snapshot(totalSeconds: t.totalSeconds,
                            sessionCount: t.sessionCount,
                            sleepLikelyCount: t.sleepLikelyCount,
                            nightSessionCount: t.nightSessionCount,
                            longestSessionSeconds: t.longestSessionSeconds,
                            activeDayCount: t.activeDays.count,
                            streak: t.currentStreak)
        }
    }

    var body: some View {
        ZStack {
            StarryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    if tracker.isEmpty {
                        emptyState()
                    } else {
                        totalCard()
                        statsCard()
                        noteFootnote()
                    }
                    feedbackCard()
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.vertical, DS.Spacing.md)
            }
            .dsConstrainedWidth()
        }
        .navigationTitle(L.Recap.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showFeedback) {
            FeedbackView()
        }
        .onAppear { tracker = .current() }
    }

    // MARK: - 카드

    /// 이 화면의 대표 수치. 다른 무엇보다 **재워 준 시간**이 먼저 와야 한다 —
    /// 사용자가 자기 효용을 체감하는 건 세션 수가 아니라 누적 시간이다.
    @ViewBuilder
    private func totalCard() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L.Recap.total.localized)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
            Text(duration(tracker.totalSeconds))
                .font(DS.Font.largeTitle())
                .foregroundColor(DS.Colors.accent)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassPanel(radius: DS.Radius.md)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statsCard() -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                            GridItem(.flexible(), alignment: .leading)],
                  spacing: DS.Spacing.lg) {
            stat(L.Recap.slept.localized, count(tracker.sleepLikelyCount, L.Recap.timesFormat))
            stat(L.Recap.streak.localized, count(tracker.streak, L.Recap.daysFormat))
            stat(L.Recap.activeDays.localized, count(tracker.activeDayCount, L.Recap.daysFormat))
            stat(L.Recap.night.localized, count(tracker.nightSessionCount, L.Recap.timesFormat))
            stat(L.Recap.longest.localized, duration(tracker.longestSessionSeconds))
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassPanel(radius: DS.Radius.md)
    }

    @ViewBuilder
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
            Text(value)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    /// 추정이라는 사실과, 이 기록이 기기 밖으로 나가지 않는다는 사실.
    /// 둘 다 **작게라도 반드시 화면에 있어야 한다** — 앞의 것은 오해를, 뒤의 것은 불안을 막는다.
    @ViewBuilder
    private func noteFootnote() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(L.Recap.estimateNote.localized)
            Text(L.Recap.localNote.localized)
        }
        .font(DS.Font.caption())
        .foregroundColor(DS.Colors.textTertiary)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 34, weight: .light))
                .foregroundColor(DS.Colors.textTertiary)
            Text(L.Recap.empty.localized)
                .font(DS.Font.subhead())
                .foregroundColor(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxl)
    }

    /// 자기 기록을 본 **직후**가 의견을 남기기 가장 쉬운 순간이다 — 그래서 여기에 둔다.
    /// 기록이 아직 없어도 보여준다(안 맞아서 안 쓴 사람의 이야기가 오히려 더 필요하다).
    @ViewBuilder
    private func feedbackCard() -> some View {
        Button { showFeedback = true } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "envelope")
                    .font(.system(size: 17))
                    .foregroundColor(DS.Colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.Recap.feedbackTitle.localized)
                        .font(DS.Font.subhead().weight(.semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                    Text(L.Recap.feedbackBody.localized)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsGlassPanel(radius: DS.Radius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.Recap.feedbackTitle.localized)
    }

    // MARK: - 포맷

    /// "3시간 20분" / "3 hours, 20 minutes".
    /// ⚠️ 직접 문자열을 조립하지 않는다 — 시간 단위 표기는 언어마다 규칙이 달라서
    ///    포맷 문자열로 옮기면 어느 한쪽이 반드시 어색해진다.
    private func duration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = seconds < 3600 ? [.minute] : [.hour, .minute]
        formatter.zeroFormattingBehavior = .dropAll
        // 1분이 안 되면 위 설정으로는 빈 문자열이 나온다 — 0분으로 떨어뜨린다.
        return formatter.string(from: max(seconds, 60)) ?? "-"
    }

    private func count(_ value: Int, _ key: String) -> String {
        String(format: key.localized, value)
    }
}

// MARK: - Preview

struct ListeningRecapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ListeningRecapView() }
    }
}
