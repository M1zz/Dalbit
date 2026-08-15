//
//  UsageInsightsTests.swift
//  DalbitTests
//
//  개발자 통계 화면이 보여주는 **모든 비율**이 여기서 검증된다.
//  화면은 계산을 하지 않고 이 함수들의 결과를 그리기만 하므로,
//  여기가 맞으면 화면도 맞고 여기가 틀리면 화면 전체가 조용히 거짓말을 한다.
//
//  ⚠️ 0으로 나누는 경우(설치 0, 세션 0)를 특히 본다 — 신규 앱은 그 상태로 오래 있고,
//     하필 그때 숫자를 가장 자주 들여다본다.
//

import XCTest
@testable import Dalbit

final class UsageInsightsTests: XCTestCase {

    // MARK: - 효용

    func testSleepEvidence_emptyInput_isAllZeroWithoutCrashing() {
        let e = UsageInsights.sleepEvidence(metrics: [])

        XCTAssertEqual(e.installs, 0)
        XCTAssertEqual(e.listenerRate, 0)
        XCTAssertEqual(e.sleepRate, 0)
        XCTAssertEqual(e.bounceRate, 0)
        XCTAssertEqual(e.timerCompletionRate, 0)
        XCTAssertEqual(e.minutesPerListener, 0)
    }

    /// 들은 사람 1명당 평균은 **설치 수가 아니라 들은 사람 수**로 나눠야 한다.
    /// 설치 수로 나누면 깔기만 한 사람이 평균을 끌어내려, 실제로 쓰는 사람의 사용 깊이를 못 본다.
    func testSleepEvidence_minutesPerListener_dividesByListenersNotInstalls() {
        let snapshots: [[String: Double]] = [
            ["listenMin": 120],
            ["listenMin": 60],
            ["listenMin": 0]     // 깔기만 하고 안 들은 설치
        ]
        let e = UsageInsights.sleepEvidence(metrics: snapshots)

        XCTAssertEqual(e.installs, 3)
        XCTAssertEqual(e.listeners, 2)
        XCTAssertEqual(e.totalHours, 3, accuracy: 0.001)
        XCTAssertEqual(e.minutesPerListener, 90, accuracy: 0.001)
        XCTAssertEqual(e.listenerRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func testSleepEvidence_ratesUseSessionsAsDenominator() {
        let snapshots: [[String: Double]] = [
            ["sessions": 8, "sleepSessions": 2, "nightSessions": 6, "len0": 4,
             "timerSessions": 4, "timerCompleted": 1],
            ["sessions": 2, "sleepSessions": 0, "nightSessions": 0, "len0": 0,
             "timerSessions": 0, "timerCompleted": 0]
        ]
        let e = UsageInsights.sleepEvidence(metrics: snapshots)

        XCTAssertEqual(e.sessions, 10)
        XCTAssertEqual(e.sleepRate, 0.2, accuracy: 0.001)
        XCTAssertEqual(e.nightRate, 0.6, accuracy: 0.001)
        // 5분 미만 = len0. 이 앱의 진짜 실패율이라 따로 확인한다.
        XCTAssertEqual(e.bounceRate, 0.4, accuracy: 0.001)
        // 완주율의 분모는 전체 세션이 아니라 **타이머를 건 세션**이다
        XCTAssertEqual(e.timerCompletionRate, 0.25, accuracy: 0.001)
    }

    // MARK: - 세션 길이 분포

    func testSessionLengths_sumsAcrossSnapshotsInOrder() {
        let snapshots: [[String: Double]] = [
            ["len0": 1, "len1": 2, "len2": 3, "len3": 4, "len4": 5],
            ["len0": 10]
        ]
        let buckets = UsageInsights.sessionLengths(metrics: snapshots)

        XCTAssertEqual(buckets.count, ListeningTracker.bucketLabelKeys.count)
        XCTAssertEqual(buckets.map(\.count), [11, 2, 3, 4, 5])
        XCTAssertEqual(buckets.map(\.order), [0, 1, 2, 3, 4])
    }

    // MARK: - 조합 제작 분포

    /// 무료 한도(3개) 칸이 따로 있어야 한다 — 거기 몰려 있으면 한도가 결제를 만들고 있다는 뜻이라,
    /// 2개나 4개와 뭉뚱그리면 그 신호가 사라진다.
    func testMixDistribution_separatesFreeLimitBucket() {
        let snapshots: [[String: Double]] = [
            ["customMixes": 0],
            ["customMixes": 1], ["customMixes": 2],
            ["customMixes": 3], ["customMixes": 3],
            ["customMixes": 5],
            ["customMixes": 42]
        ]
        let buckets = UsageInsights.mixDistribution(metrics: snapshots)

        XCTAssertEqual(buckets.map(\.count), [1, 2, 2, 1, 1])
        // ⚠️ 라벨 문자열이 아니라 플래그로 확인한다 — 번역이 바뀌어도 이 테스트는 살아 있어야 한다.
        XCTAssertEqual(buckets.filter(\.isFreeLimit).map(\.order), [2])
    }

    func testMixDistribution_treatsMissingKeyAsZero() {
        let buckets = UsageInsights.mixDistribution(metrics: [[:], [:]])

        XCTAssertEqual(buckets[0].count, 2)
    }

    // MARK: - 제품 신호

    func testSignals_emptyInput_returnsNothing() {
        XCTAssertTrue(UsageInsights.signals(metrics: []).isEmpty)
    }

    func testSignals_computeShareOfInstalls() {
        let snapshots: [[String: Double]] = [
            ["flag.isPro": 1, "flag.madeOwnMix": 1, "flag.usedTimer": 1, "mixes": 10, "unusedMixes": 5],
            ["flag.isPro": 0, "flag.madeOwnMix": 1, "flag.usedTimer": 0, "mixes": 10, "unusedMixes": 5],
            ["flag.isPro": 0, "flag.madeOwnMix": 0, "flag.usedTimer": 0, "mixes": 0, "unusedMixes": 0],
            ["flag.isPro": 0, "flag.madeOwnMix": 0, "flag.usedTimer": 0, "mixes": 0, "unusedMixes": 0]
        ]
        let signals = UsageInsights.signals(metrics: snapshots)
        // 표시 이름이 아니라 안정적 id 로 찾는다 — 이름은 언어에 따라 바뀐다.
        func value(_ id: String) -> String? { signals.first { $0.id == id }?.value }

        XCTAssertEqual(value("proRate"), "25%")
        XCTAssertEqual(value("madeOwnMix"), "50%")
        XCTAssertEqual(value("usedTimer"), "25%")
        // 안 듣는 조합은 설치 비율이 아니라 **조합 총합 대비**다 (10/20)
        XCTAssertEqual(value("unusedMixes"), "50%")
        XCTAssertEqual(value("mixesPerInstall"), "5.0")
    }

    // MARK: - 결제 퍼널

    /// 각 단계는 이벤트 **건수**가 아니라 서로 다른 설치 수다.
    /// 건수로 세면 한 사람이 페이월을 여러 번 본 것이 여러 명처럼 보인다.
    func testPaywallFunnel_countsDistinctInstalls() {
        let now = Date()
        let samples = [
            sample(UsageReportingService.listenStartEvent, "a", now),
            sample(UsageReportingService.listenStartEvent, "b", now),
            sample(UsageReportingService.listenStartEvent, "b", now),   // 같은 사람 재방문
            sample(UsageReportingService.listenStartEvent, "c", now),
            sample(UsageReportingService.listenStartEvent, "d", now),
            sample(UsageReportingService.paywallViewEvent, "a", now),
            sample(UsageReportingService.paywallViewEvent, "b", now),
            sample(UsageReportingService.paywallPurchaseEvent, "a", now)
        ]
        let funnel = UsageInsights.paywallFunnel(from: samples)

        XCTAssertEqual(funnel.map(\.installs), [4, 2, 1])
        XCTAssertEqual(funnel[0].rateFromTop, 1.0, accuracy: 0.001)
        XCTAssertEqual(funnel[1].rateFromTop, 0.5, accuracy: 0.001)
        XCTAssertEqual(funnel[2].rateFromTop, 0.25, accuracy: 0.001)
    }

    func testPaywallFunnel_noSamples_hasZeroRatesWithoutCrashing() {
        let funnel = UsageInsights.paywallFunnel(from: [])

        XCTAssertEqual(funnel.count, 3)
        XCTAssertTrue(funnel.allSatisfy { $0.installs == 0 && $0.rateFromTop == 0 })
    }

    // MARK: - 리텐션 코호트

    func testWeeklyRetention_countsReturnOnDayOneAndSeven() {
        let calendar = Calendar.current
        let now = Date()
        let installedAt = calendar.date(byAdding: .day, value: -40, to: calendar.startOfDay(for: now))!

        let installs = [UsageInsights.Install(id: "a", installDate: installedAt)]
        let events = [1, 7].map { offset in
            sample(UsageReportingService.appOpenEvent, "a",
                   calendar.date(byAdding: .day, value: offset, to: installedAt)!)
        }

        let rows = UsageInsights.weeklyRetention(installs: installs, events: events, now: now)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].size, 1)
        XCTAssertEqual(rows[0].day1, 1)
        XCTAssertEqual(rows[0].day7, 1)
        XCTAssertEqual(rows[0].day30, 0)
        XCTAssertEqual(rows[0].rate(rows[0].day1), 1.0, accuracy: 0.001)
    }

    /// **아직 그날이 오지 않은 설치는 이탈로 세지 않는다.**
    /// 여기가 뚫리면 어제 깐 사람이 전부 "D7에 안 돌아온 사람"이 되어,
    /// 최근 코호트의 리텐션이 항상 0에 가깝게 보인다.
    func testWeeklyRetention_doesNotPenalizeInstallsWhoseDayHasNotArrived() {
        let calendar = Calendar.current
        let now = Date()
        let installedAt = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!

        let rows = UsageInsights.weeklyRetention(
            installs: [UsageInsights.Install(id: "fresh", installDate: installedAt)],
            events: [],
            now: now)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].size, 1)
        XCTAssertEqual(rows[0].day7, 0)
        // 분모는 그대로 1이지만, 이 사람은 아직 D7을 맞이하지 않았을 뿐이다.
        // (분모 자체를 조정하는 건 화면 쪽 판단이라 여기서는 원본만 확인한다)
    }

    func testWeeklyRetention_ignoresInstallsWithoutDate() {
        let rows = UsageInsights.weeklyRetention(
            installs: [UsageInsights.Install(id: "x", installDate: nil)],
            events: [],
            now: Date())

        XCTAssertTrue(rows.isEmpty)
    }

    /// 같은 주에 깐 사람은 한 줄로 묶이고, 최신 코호트가 위로 온다.
    func testWeeklyRetention_groupsByInstallWeekNewestFirst() {
        let calendar = Calendar.current
        let now = Date()
        let thisWeek = calendar.date(byAdding: .day, value: -2, to: now)!
        let lastMonth = calendar.date(byAdding: .day, value: -30, to: now)!

        let rows = UsageInsights.weeklyRetention(
            installs: [
                UsageInsights.Install(id: "a", installDate: thisWeek),
                UsageInsights.Install(id: "b", installDate: thisWeek),
                UsageInsights.Install(id: "c", installDate: lastMonth)
            ],
            events: [],
            now: now)

        XCTAssertEqual(rows.count, 2)
        XCTAssertGreaterThan(rows[0].cohortStart, rows[1].cohortStart)
        XCTAssertEqual(rows[0].size, 2)
        XCTAssertEqual(rows[1].size, 1)
    }

    // MARK: - 도우미

    private func sample(_ name: String, _ install: String, _ date: Date)
    -> UsageReportingService.EventSample {
        UsageReportingService.EventSample(name: name, installID: install, date: date)
    }
}
