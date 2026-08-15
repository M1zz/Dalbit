//
//  UsageReportingServiceTests.swift
//  DalbitTests
//
//  허브에서 읽어 온 **원본 표본을 화면용 수치로 접는** 부분만 검증한다.
//  전송·조회는 CloudKit 이라 여기서 다루지 않는다(그쪽은 LeeoKit 책임).
//

import XCTest
@testable import Dalbit

final class UsageReportingServiceTests: XCTestCase {

    // MARK: - 이름별 집계

    /// 건수와 설치 수는 다른 값이다 — 한 사람이 여러 번 남긴 이벤트가 여러 명으로 보이면
    /// "몇 명이 이 기능을 쓰는가"라는 질문에 답할 수 없게 된다.
    func testEventStats_separatesCountFromDistinctInstalls() {
        let now = Date()
        let older = now.addingTimeInterval(-3600)
        let samples = [
            sample("listen_start", "a", older),
            sample("listen_start", "a", now),
            sample("listen_start", "b", older),
            sample("timer_start", "a", older)
        ]

        let stats = UsageReportingService.eventStats(from: samples)
        func stat(_ name: String) -> UsageReportingService.EventStat? {
            stats.first { $0.name == name }
        }

        XCTAssertEqual(stat("listen_start")?.count, 3)
        XCTAssertEqual(stat("listen_start")?.installs, 2)
        XCTAssertEqual(stat("listen_start")?.lastAt, now)
        XCTAssertEqual(stat("timer_start")?.count, 1)
        // 많이 발생한 순으로 정렬된다
        XCTAssertEqual(stats.first?.name, "listen_start")
    }

    func testEventStats_toleratesMissingInstallID() {
        let stats = UsageReportingService.eventStats(from: [
            UsageReportingService.EventSample(name: "listen_start", installID: nil, date: Date())
        ])

        XCTAssertEqual(stats.first?.count, 1)
        XCTAssertEqual(stats.first?.installs, 0)
    }

    func testEventStats_emptyInput() {
        XCTAssertTrue(UsageReportingService.eventStats(from: []).isEmpty)
    }

    // MARK: - 기간별 추이

    /// 활동한 사람은 `app_open`, 잠든 사람은 `sleep_session` 으로 각각 **중복 없이** 센다.
    func testTrend_countsDistinctInstallsPerSeries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let samples = [
            sample(UsageReportingService.appOpenEvent, "a", today),
            sample(UsageReportingService.appOpenEvent, "a", today.addingTimeInterval(600)),
            sample(UsageReportingService.appOpenEvent, "b", today),
            sample(UsageReportingService.sleepSessionEvent, "a", today)
        ]

        let points = UsageReportingService.trend(unit: .day,
                                                 events: samples,
                                                 installDates: [],
                                                 now: today)

        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].activeInstalls, 2)
        XCTAssertEqual(points[0].sleepInstalls, 1)
    }

    /// 빈 날도 점을 만들어야 선 그래프가 끊기지 않는다.
    func testTrend_fillsGapDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let points = UsageReportingService.trend(
            unit: .day,
            events: [sample(UsageReportingService.appOpenEvent, "a", threeDaysAgo)],
            installDates: [],
            now: today)

        XCTAssertEqual(points.count, 4)                  // 3일 전 ~ 오늘
        XCTAssertEqual(points[0].activeInstalls, 1)
        XCTAssertEqual(points[1].activeInstalls, 0)
        XCTAssertEqual(points.last?.date, today)
    }

    func testTrend_countsNewInstallsFromInstallDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let points = UsageReportingService.trend(unit: .day,
                                                 events: [],
                                                 installDates: [today, today, nil],
                                                 now: today)

        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].newInstalls, 2)         // nil 은 세지 않는다
    }

    func testTrend_noDataReturnsEmpty() {
        XCTAssertTrue(UsageReportingService.trend(unit: .day, events: [], installDates: []).isEmpty)
    }

    /// 주 단위로 묶으면 같은 주의 서로 다른 날이 한 점이 된다.
    func testTrend_weekUnitCollapsesDaysInSameWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        let samples = [
            sample(UsageReportingService.appOpenEvent, "a", weekStart),
            sample(UsageReportingService.appOpenEvent, "b", weekStart.addingTimeInterval(2 * 24 * 3600))
        ]

        let points = UsageReportingService.trend(unit: .week,
                                                 events: samples,
                                                 installDates: [],
                                                 calendar: calendar,
                                                 now: weekStart.addingTimeInterval(2 * 24 * 3600))

        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].activeInstalls, 2)
    }

    // MARK: - 이벤트 목록

    /// 정의한 이벤트를 진단 목록에 넣는 걸 잊으면 "안 나가고 있다"를 눈치채지 못한다.
    func testAllEventNames_coversEveryDeclaredEvent() {
        let declared = [
            UsageReportingService.appOpenEvent,
            UsageReportingService.listenStartEvent,
            UsageReportingService.listenNightEvent,
            UsageReportingService.sleepSessionEvent,
            UsageReportingService.timerStartEvent,
            UsageReportingService.timerCompleteEvent,
            UsageReportingService.timerCancelEvent,
            UsageReportingService.mixCreateEvent,
            UsageReportingService.favoriteAddEvent,
            UsageReportingService.paywallViewEvent,
            UsageReportingService.paywallPurchaseEvent
        ]

        XCTAssertEqual(Set(UsageReportingService.allEventNames), Set(declared))
        // 이름이 겹치면 쓰로틀 키가 충돌해 한쪽이 조용히 사라진다
        XCTAssertEqual(UsageReportingService.allEventNames.count, Set(declared).count)
    }

    // MARK: - 도우미

    private func sample(_ name: String, _ install: String, _ date: Date)
    -> UsageReportingService.EventSample {
        UsageReportingService.EventSample(name: name, installID: install, date: date)
    }
}
