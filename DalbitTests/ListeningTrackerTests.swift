//
//  ListeningTrackerTests.swift
//  DalbitTests
//
//  청취 원장 — **효용 지표 전체가 이 파일의 판정 하나에 걸려 있다.**
//  "잠들었다"를 잘못 세면 개발자 통계의 대표 수치가 통째로 거짓이 되고,
//  그 숫자를 근거로 내리는 제품 결정도 같이 틀어진다.
//
//  ⚠️ 여기서 세션을 인위적으로 만들려면 열린 세션 키를 직접 써 넣어야 한다
//     (`end()` 는 종료 시각으로 `Date()` 를 쓰기 때문에 긴 세션을 만들 방법이 없다).
//     키 이름은 ListeningTracker 의 내부 규약이라 아래 `seedOpenSession` 한 곳에만 둔다 —
//     구현이 바뀌면 이 함수만 고치면 된다.
//

import XCTest
@testable import Dalbit

final class ListeningTrackerTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "dalbit.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeTracker() -> ListeningTracker {
        ListeningTracker(defaults: defaults)
    }

    /// 열린 세션을 과거 시각으로 심는다 — 앱이 재생 중에 죽은 상황의 재현.
    private func seedOpenSession(start: Date, heartbeat: Date, timerMinutes: Int? = nil) {
        defaults.set(start, forKey: "dalbit.listen.openStart")
        defaults.set(heartbeat, forKey: "dalbit.listen.heartbeat")
        if let timerMinutes { defaults.set(timerMinutes, forKey: "dalbit.listen.openTimerMin") }
    }

    // MARK: - 잠들었다는 판정

    /// 타이머를 끝까지 두었다면 길이와 무관하게 잠든 것으로 본다 —
    /// 짧은 타이머(10분)를 걸고 잠드는 사람이 실제로 있다.
    func testSleepLikely_timerCompleted_isTrueRegardlessOfDuration() {
        XCTAssertTrue(ListeningTracker.isSleepLikely(reason: .timerCompleted, duration: 1))
        XCTAssertTrue(ListeningTracker.isSleepLikely(reason: .timerCompleted, duration: 8 * 3600))
    }

    /// 방치 종료는 30분이 경계다. 경계값을 못 박아 둔다 — 이 숫자가 바뀌면
    /// 과거 지표와 이후 지표를 나란히 놓고 비교할 수 없게 된다.
    func testSleepLikely_orphaned_thresholdIsThirtyMinutes() {
        XCTAssertFalse(ListeningTracker.isSleepLikely(reason: .orphaned, duration: 30 * 60 - 1))
        XCTAssertTrue(ListeningTracker.isSleepLikely(reason: .orphaned, duration: 30 * 60))
    }

    /// **직접 껐다면 아무리 길어도 깨어 있었다.**
    /// 여기가 뚫리면 "8시간 틀어 놓고 공부한 사람"이 잠든 사람으로 집계된다.
    func testSleepLikely_userStoppedAndCancelled_areNeverSleep() {
        XCTAssertFalse(ListeningTracker.isSleepLikely(reason: .userStopped, duration: 8 * 3600))
        XCTAssertFalse(ListeningTracker.isSleepLikely(reason: .timerCancelled, duration: 8 * 3600))
    }

    // MARK: - 앱이 재생 중에 죽었을 때

    /// 이 앱에서 가장 흔한 종료 경로다. 마지막 생존 신호까지만 인정해야 한다 —
    /// "지금"으로 닫으면 며칠 뒤 앱을 연 사람의 청취 시간이 며칠치로 부푼다.
    func testOrphanSession_countsOnlyUntilLastHeartbeat() {
        let start = Date().addingTimeInterval(-3 * 24 * 3600)      // 3일 전에 재생 시작
        let heartbeat = start.addingTimeInterval(45 * 60)          // 45분 듣다가 앱이 죽음
        seedOpenSession(start: start, heartbeat: heartbeat)

        let tracker = makeTracker()   // init 에서 고아 세션을 닫는다

        XCTAssertEqual(tracker.sessionCount, 1)
        XCTAssertEqual(tracker.totalSeconds, 45 * 60, accuracy: 1)
        // 45분 방치 종료 → 잠든 것으로 본다
        XCTAssertEqual(tracker.sleepLikelyCount, 1)
    }

    /// 생존 신호가 깨졌거나 기기 시계가 튀어도 하루치가 통째로 잡히면 안 된다.
    func testOrphanSession_isCappedAtTwelveHours() {
        let start = Date().addingTimeInterval(-40 * 3600)
        seedOpenSession(start: start, heartbeat: Date())

        let tracker = makeTracker()

        XCTAssertEqual(tracker.totalSeconds, 12 * 3600, accuracy: 1)
    }

    // MARK: - 세션 기록

    func testEndWithoutBegin_doesNothing() {
        let tracker = makeTracker()
        tracker.end(reason: .userStopped)

        XCTAssertEqual(tracker.sessionCount, 0)
        XCTAssertEqual(tracker.totalSeconds, 0)
    }

    /// 1초를 못 넘긴 것은 오조작이다 — 세면 "5분 미만" 비율이 거짓으로 부푼다.
    func testVeryShortSession_isNotCounted() {
        let tracker = makeTracker()
        tracker.begin()
        tracker.end(reason: .userStopped)

        XCTAssertEqual(tracker.sessionCount, 0)
    }

    func testCompletedSession_recordsDayAndBucket() {
        // ⚠️ 트래커를 **먼저** 만든다 — init 이 열린 세션을 고아로 닫아 버리므로,
        //    직접 종료하는 경로를 보려면 심기 전에 인스턴스가 있어야 한다.
        let tracker = makeTracker()
        seedOpenSession(start: Date().addingTimeInterval(-20 * 60), heartbeat: Date())

        tracker.end(reason: .userStopped)

        XCTAssertEqual(tracker.sessionCount, 1)
        XCTAssertEqual(tracker.activeDays.count, 1)
        // 15~30분 구간
        XCTAssertEqual(tracker.lengthBuckets[2], 1)
        // 직접 껐으니 아무리 길어도 잠든 것으로 세지 않는다
        XCTAssertEqual(tracker.sleepLikelyCount, 0)
    }

    /// 구간 경계 — `분 < 상한` 이므로 5분은 "5분 미만"이 아니라 다음 칸이다.
    func testBucketBoundary_fiveMinuteMarkBelongsToSecondBucket() {
        let justUnder = makeTracker()
        seedOpenSession(start: Date().addingTimeInterval(-(5 * 60 - 2)), heartbeat: Date())
        justUnder.end(reason: .userStopped)
        XCTAssertEqual(justUnder.lengthBuckets[0], 1, "4분 58초는 5분 미만 칸")
        XCTAssertEqual(justUnder.lengthBuckets[1], 0)

        let atMark = makeTracker()
        seedOpenSession(start: Date().addingTimeInterval(-5 * 60), heartbeat: Date())
        atMark.end(reason: .userStopped)
        XCTAssertEqual(atMark.lengthBuckets[0], 1, "앞 세션은 그대로")
        XCTAssertEqual(atMark.lengthBuckets[1], 1, "5분은 5~15분 칸")
    }

    // MARK: - 타이머

    /// **곡을 넘겨도 걸어 둔 타이머는 살아 있어야 한다.**
    /// 여기가 뚫리면 자다가 곡이 한 번 넘어간 사람 전부가 "타이머를 안 쓴 사람"이 되고,
    /// 타이머 완주율(가장 믿을 만한 수면 신호)이 실제보다 낮게 나온다.
    func testTimerSurvivesTrackChange() {
        let tracker = makeTracker()
        tracker.begin(timerMinutes: 30)
        tracker.begin()   // 곡 전환

        XCTAssertEqual(tracker.currentTimerMinutes, 30)
    }

    /// 완주는 "잠들었다"의 가장 믿을 만한 근거라 세 값이 함께 올라야 한다.
    func testTimerCompleted_countsSessionCompletionAndSleep() {
        let tracker = makeTracker()
        seedOpenSession(start: Date().addingTimeInterval(-10 * 60), heartbeat: Date(), timerMinutes: 10)

        tracker.end(reason: .timerCompleted)

        XCTAssertEqual(tracker.timerSessionCount, 1)
        XCTAssertEqual(tracker.timerCompletedCount, 1)
        XCTAssertEqual(tracker.sleepLikelyCount, 1)
    }

    /// 도중에 껐다면 타이머를 건 세션으로는 세되 완주·수면으로는 세지 않는다.
    func testTimerCancelled_countsSessionButNotCompletion() {
        let tracker = makeTracker()
        seedOpenSession(start: Date().addingTimeInterval(-10 * 60), heartbeat: Date(), timerMinutes: 30)

        tracker.end(reason: .timerCancelled)

        XCTAssertEqual(tracker.timerSessionCount, 1)
        XCTAssertEqual(tracker.timerCompletedCount, 0)
        XCTAssertEqual(tracker.sleepLikelyCount, 0)
    }


    // MARK: - 일자별 원장 (사용 시간·빈도)

    /// 세션이 끝나면 그날 칸에 시간과 횟수가 함께 쌓여야 한다.
    func testDailyLedger_accumulatesSecondsAndSessions() {
        let tracker = makeTracker()
        let today = ListeningTracker.dayKey(for: Date())

        for _ in 0..<2 {
            seedOpenSession(start: Date().addingTimeInterval(-10 * 60), heartbeat: Date())
            tracker.end(reason: .userStopped)
        }

        XCTAssertEqual(tracker.dailySessions[today], 2)
        XCTAssertEqual(tracker.dailySeconds[today] ?? 0, 20 * 60, accuracy: 5)
        XCTAssertEqual(tracker.recentSessions(days: 7), 2)
        XCTAssertEqual(tracker.recentMinutes(days: 7), 20, accuracy: 0.5)
        XCTAssertEqual(tracker.recentActiveDays(days: 7), 1)
    }

    /// 최근 창은 **창 밖의 기록을 세면 안 된다** — 그러면 누적값과 다를 게 없어진다.
    func testRecentWindow_excludesOlderDays() {
        let calendar = Calendar.current
        let now = Date()
        let old = ListeningTracker.dayKey(for: calendar.date(byAdding: .day, value: -20, to: now)!)
        let recent = ListeningTracker.dayKey(for: calendar.date(byAdding: .day, value: -2, to: now)!)
        defaults.set([old: 600.0, recent: 300.0], forKey: "dalbit.listen.dailySeconds")
        defaults.set([old: 3, recent: 1], forKey: "dalbit.listen.dailySessions")
        defaults.set([old, recent].sorted(), forKey: "dalbit.listen.activeDays")

        let tracker = makeTracker()
        XCTAssertEqual(tracker.recentMinutes(days: 7, now: now), 5, accuracy: 0.01)
        XCTAssertEqual(tracker.recentMinutes(days: 30, now: now), 15, accuracy: 0.01)
        XCTAssertEqual(tracker.recentActiveDays(days: 7, now: now), 1)
        XCTAssertEqual(tracker.recentActiveDays(days: 30, now: now), 2)
        XCTAssertEqual(tracker.recentSessions(days: 7, now: now), 1)
    }

    /// 자정을 넘긴 세션은 **시작한 날**에 몰아 준다.
    /// 하루를 쪼개 나누면 한 번 잔 것이 이틀 들은 것으로 잡혀 빈도가 부풀어 오른다.
    func testOvernightSession_countsOnStartDayOnly() {
        let calendar = Calendar.current
        // 어제 23:30 시작 → 오늘 새벽까지
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let start = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: yesterday)!
        let tracker = makeTracker()
        seedOpenSession(start: start, heartbeat: start.addingTimeInterval(3 * 3600))
        tracker.end(reason: .orphaned)

        XCTAssertEqual(tracker.dailySessions.count, 1)
        XCTAssertEqual(tracker.dailySessions[ListeningTracker.dayKey(for: start)], 1)
    }

    /// 시간대 칸은 4시간씩 6칸이고, 세션이 **시작한** 시각으로 들어간다.
    func testHourBuckets_useSessionStartHour() {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        let tracker = makeTracker()
        seedOpenSession(start: start, heartbeat: start.addingTimeInterval(600))
        tracker.end(reason: .orphaned)

        XCTAssertEqual(tracker.hourBuckets.count, ListeningTracker.hourBucketCount)
        XCTAssertEqual(tracker.hourBuckets[5], 1, "23시는 20~24 칸")
        XCTAssertEqual(tracker.hourBuckets.reduce(0, +), 1)
    }

    /// 현재 줄이 끊겨도 최장 기록은 남아야 한다 — "한때 습관이었나"는 다른 질문이다.
    func testBestStreak_survivesBrokenCurrentStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // 20~18일 전 3일 연속으로 들었고, 그 뒤로는 안 들었다
        let days = [20, 19, 18].map {
            ListeningTracker.dayKey(for: calendar.date(byAdding: .day, value: -$0, to: today)!)
        }
        defaults.set(days.sorted(), forKey: "dalbit.listen.activeDays")
        defaults.set(3, forKey: "dalbit.listen.bestStreak")

        let tracker = makeTracker()
        XCTAssertEqual(tracker.currentStreak, 0)
        XCTAssertEqual(tracker.bestStreak, 3)
        XCTAssertEqual(tracker.daysSinceLastListen, 18)
    }

    func testDaysSinceLastListen_isNilWithNoHistory() {
        XCTAssertNil(makeTracker().daysSinceLastListen)
    }

    // MARK: - 연속일

    /// 자정을 넘긴 직후에 줄이 끊긴 것처럼 보이면 안 된다 — 오늘 밤은 아직 오지 않았다.
    func testStreak_survivesUntilTodayEnds() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (1...3).map {
            ListeningTracker.dayKey(for: calendar.date(byAdding: .day, value: -$0, to: today)!)
        }
        defaults.set(days.sorted(), forKey: "dalbit.listen.activeDays")

        // 어제·그저께·그끄저께를 들었고 오늘은 아직 안 들었다 → 줄은 3일로 살아 있다
        XCTAssertEqual(makeTracker().currentStreak, 3)
    }

    func testStreak_breaksWhenADayIsMissed() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // 어제와 나흘 전 — 사이가 비었다
        let days = [1, 4].map {
            ListeningTracker.dayKey(for: calendar.date(byAdding: .day, value: -$0, to: today)!)
        }
        defaults.set(days.sorted(), forKey: "dalbit.listen.activeDays")

        XCTAssertEqual(makeTracker().currentStreak, 1)
    }

    func testStreak_isZeroWithNoHistory() {
        XCTAssertEqual(makeTracker().currentStreak, 0)
    }
}
