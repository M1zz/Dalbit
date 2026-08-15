//
//  UsageReportingService.swift
//  Dalbit
//
//  익명 사용 통계 — 피드백과 같은 공용 허브(FeedbackHub, CloudKit public DB)로 보내고 읽는다.
//  전송 엔진은 LeeoKit(LeeoUsageReporter)이고, 여기서는 이 앱의 지표·이벤트 정책만 정한다.
//
//  보내는 것
//   ① UsageSnapshot — 설치당 1개(익명 UUID recordName, upsert). 사용자 수/활성 사용자 집계용.
//   ② UsageEvent — 주요 행동 스트림(이름만). 이름당 6시간 쓰로틀.
//
//  ⚠️ PII 없음: 기기/계정 식별자는 물론 **소리 제목도 보내지 않는다.** 제목은 사용자가
//     직접 지은 이름이라(아이 이름·연인 이름이 흔하다) 익명 지표가 아니다.
//     보내는 값은 개수·분 단위 수치와 0/1 플래그, 그리고 고정된 이벤트 이름뿐이다.
//  ⚠️ 옵트아웃 없음 — 대신 원격 킬스위치가 있다(usageReportingEnabled). 수집 항목을 늘릴 땐
//     "이게 익명 집계 수치인가"를 매번 다시 따질 것.
//  ⚠️ CloudKit Dashboard 에 UsageSnapshot/UsageEvent 스키마 배포가 선행되어야 한다.
//     절차: docs/USAGE_STATS_HUB.md
//

import Foundation
import CloudKit
import LeeoKit

enum UsageReportingService {

    private static var reporter: LeeoUsageReporter {
        LeeoUsageReporter(spec: DalbitSpec.self)
    }

    /// 같은 이벤트 이름을 다시 보내기까지의 최소 간격 — 공개 DB 쓰기 폭주 방지.
    private static let eventThrottle: TimeInterval = 6 * 3600

    /// 테스트 중에는 허브에 실제로 쓰지 않는다(쓰로틀 로직 자체는 그대로 검증된다).
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// 수집을 멈추는 단 하나의 지점.
    ///
    /// **원격 킬스위치**다 — 심사(5.1.1(ii)) 지적이나 개인정보 문의를 받으면 CloudKit
    /// Dashboard 에서 `RemoteFlags` 레코드의 `usageReportingEnabled` 를 0 으로 내리는 것만으로
    /// 새 빌드 심사 없이 즉시 수집이 멈춘다. 절차: docs/USAGE_STATS_HUB.md
    ///
    /// ⚠️ 조회 실패 시 기본값은 **켬**이다(LeeoRemoteFlags 가 그렇게 동작한다) — 네트워크
    ///    문제로 수집이 임의로 멈추면 킬스위치가 오히려 장애 원인이 된다.
    /// ⚠️ 로컬 스위치(`dalbit.usage.disabled`)는 그대로 둔다. 원격이 닿지 않는 상황
    ///    (컨테이너 장애·기내 모드 디버깅)에서 손으로 끌 수 있는 최후 수단이다.
    private static var isReportingAllowed: Bool {
        guard !UserDefaults.standard.bool(forKey: "dalbit.usage.disabled") else { return false }
        return LeeoRemoteFlags.isEnabled(DalbitFlag.usageReportingEnabled)
    }

    /// 앱 시작 시 1회. 원격 플래그를 새로 받아 캐시에 넣는다(6시간 쓰로틀은 LeeoKit 담당).
    /// 실패해도 조용히 넘어간다 — 캐시가 없으면 "켬"으로 동작한다.
    static func refreshRemoteFlags() {
        LeeoRemoteFlags(spec: DalbitSpec.self).refreshInBackground(DalbitFlag.self)
    }

    // MARK: - 이벤트 이름

    /// "이 설치가 오늘 활동했다" — 일간 활성 사용자와 리텐션 코호트의 근거.
    /// 스냅샷의 lastActiveAt 은 덮어쓰기라 날짜별 이력이 남지 않아, 하루 1건 이벤트로 대신한다.
    static let appOpenEvent = "app_open"

    /// 소리를 실제로 들었다 — 앱을 연 것과 구분해야 한다. 열어만 보고 재생하지 않는 사람이 있다.
    static let listenStartEvent = "listen_start"
    /// 밤(22~04시)에 들었다 — 이 앱이 수면용으로 쓰이고 있는지의 근거.
    static let listenNightEvent = "listen_night"
    /// **잠든 것으로 보이는 세션.** 이 앱의 효용을 가장 직접적으로 대변하는 이벤트다.
    static let sleepSessionEvent = "sleep_session"

    static let timerStartEvent = "timer_start"
    static let timerCompleteEvent = "timer_complete"
    static let timerCancelEvent = "timer_cancel"

    static let mixCreateEvent = "mix_create"
    static let favoriteAddEvent = "favorite_add"

    static let paywallViewEvent = "paywall_view"
    static let paywallPurchaseEvent = "paywall_purchase"

    /// 이 앱이 보내는 이벤트 전부. 진단 카드가 쓰로틀 상태를 훑을 때 쓴다.
    /// ⚠️ 새 이벤트를 추가하면 여기에도 넣을 것 — 빠지면 "안 나가고 있다"를 눈치채지 못한다.
    static let allEventNames: [String] = [
        appOpenEvent, listenStartEvent, listenNightEvent, sleepSessionEvent,
        timerStartEvent, timerCompleteEvent, timerCancelEvent,
        mixCreateEvent, favoriteAddEvent,
        paywallViewEvent, paywallPurchaseEvent
    ]

    // MARK: - 전송

    /// **프로세스가 뜰 때** 1회. 설치 스냅샷을 갱신한다(12시간 쓰로틀은 LeeoKit 담당).
    ///
    /// ⚠️ 여기에 "사람이 앱을 열었다"는 신호를 두지 말 것. 알람·백그라운드 오디오로 깨어난
    ///    경우에도 이 경로는 돈다. 사람이 앞으로 가져온 순간은 `reportForegroundOpen()` 이 맡는다.
    static func reportProcessStart() {
        guard !isRunningTests, isReportingAllowed else { return }
        Task(priority: .utility) {
            await reporter.report(metrics: currentMetrics())
        }
    }

    /// 사람이 앱을 실제로 앞으로 가져온 순간. 콜드 런치와 백그라운드 복귀 양쪽에서 불린다.
    static func reportForegroundOpen() {
        // 실행 횟수는 프로세스당 1회만 — 리뷰 요청 타이밍이 복귀할 때마다 앞당겨지면 안 된다.
        if !didRegisterLaunch {
            didRegisterLaunch = true
            LeeoEngagement.shared.registerLaunch()
        }
        record(event: appOpenEvent, minInterval: 20 * 3600, countsAsEngagement: false)
    }

    private static var didRegisterLaunch = false

    /// 청취 세션이 끝났다 — 세션의 성격에 따라 이벤트를 남긴다.
    ///
    /// ⚠️ 세션 **끝**에 부르는 이유: 시작 시점엔 이 세션이 3분짜리인지 8시간짜리인지 알 수 없고,
    ///    효용을 가르는 건 길이와 종료 이유이지 재생 버튼을 눌렀다는 사실이 아니다.
    static func reportListeningSession(startedAt: Date,
                                       duration: TimeInterval,
                                       reason: ListeningEndReason,
                                       hadTimer: Bool) {
        record(event: listenStartEvent)

        if Calendar.current.component(.hour, from: startedAt) >= 22
            || Calendar.current.component(.hour, from: startedAt) < 5 {
            record(event: listenNightEvent, countsAsEngagement: false)
        }

        if ListeningTracker.isSleepLikely(reason: reason, duration: duration) {
            // ⚠️ 쓰로틀을 짧게 둔다 — 하루에 두 번 잠드는 사람(낮잠)이 한 번으로 뭉개지면
            //    이 앱이 가장 자랑해야 할 지표가 실제보다 작게 보인다.
            record(event: sleepSessionEvent, minInterval: 4 * 3600)
        }

        if hadTimer {
            record(event: reason == .timerCompleted ? timerCompleteEvent : timerCancelEvent,
                   countsAsEngagement: false)
        }
    }

    /// 주요 행동 1건. 로컬 참여도 카운터를 올리고, 허브 쓰기는 이름당 쓰로틀 간격에 한 번만.
    /// - Parameters:
    ///   - name: 이벤트 이름(snake_case).
    ///   - minInterval: 같은 이름을 다시 보내기까지의 최소 간격 (기본 6시간).
    ///   - countsAsEngagement: 참여도 카운터를 올릴지. 앱을 앞으로 가져온 것 자체는
    ///     "주요 행동"이 아니다 — 그건 실행 횟수가 이미 센다.
    static func record(event name: String,
                       minInterval: TimeInterval = eventThrottle,
                       countsAsEngagement: Bool = true) {
        if countsAsEngagement { LeeoEngagement.shared.registerSignificantEvent() }

        let key = "dalbit.usage.lastSent." + name
        if let last = UserDefaults.standard.object(forKey: key) as? Date,
           Date().timeIntervalSince(last) < minInterval { return }
        UserDefaults.standard.set(Date(), forKey: key)

        guard !isRunningTests, isReportingAllowed else { return }
        reporter.logEventInBackground(String(name.prefix(60)))
    }

    // MARK: - 지표

    /// 이 설치의 대략 지표 — 스냅샷 한 필드(metrics JSON)로 들어간다.
    /// 개수·분 단위 수치와 0/1 플래그만 담는다(제목·식별자 없음).
    static func currentMetrics() -> [String: Double] {
        var metrics: [String: Double] = [:]

        let tracker = ListeningTracker.shared

        // ── 효용의 핵심: 얼마나 오래, 언제, 어떻게 들었는가
        metrics["listenMin"] = (tracker.totalSeconds / 60).rounded()
        metrics["sessions"] = Double(tracker.sessionCount)
        metrics["nightSessions"] = Double(tracker.nightSessionCount)
        metrics["sleepSessions"] = Double(tracker.sleepLikelyCount)
        metrics["timerSessions"] = Double(tracker.timerSessionCount)
        metrics["timerCompleted"] = Double(tracker.timerCompletedCount)
        metrics["longestMin"] = (tracker.longestSessionSeconds / 60).rounded()
        metrics["streakDays"] = Double(tracker.currentStreak)
        metrics["activeDays"] = Double(tracker.activeDays.count)

        // 세션 길이 분포 — 짧은 세션이 두꺼우면 소리가 안 맞는 것이다.
        for (index, count) in tracker.lengthBuckets.enumerated() {
            metrics["len\(index)"] = Double(count)
        }

        // ── 핵심 가치 도달: 나만의 조합을 실제로 만드는가
        let sounds = UserDefaultsManager.shared.customSounds
        let userMade = sounds.filter { !$0.isPreset }
        metrics["mixes"] = Double(sounds.count)
        metrics["customMixes"] = Double(userMade.count)
        metrics["layeredMixes"] = Double(sounds.filter(\.isLayeredSound).count)
        metrics["favorites"] = Double(sounds.filter(\.isFavorite).count)
        metrics["plays"] = Double(sounds.reduce(0) { $0 + $1.playCount })
        metrics["topPlays"] = Double(sounds.map(\.playCount).max() ?? 0)
        // 만들어만 두고 한 번도 안 들은 조합 — 높으면 가치 전달이 덜 된 것이다.
        metrics["unusedMixes"] = Double(sounds.filter { $0.playCount == 0 }.count)

        // ── 플래그
        // SubscriptionManager 는 @MainActor 라 여기서 직접 못 읽는다 — 그쪽이 남긴 캐시를 본다.
        metrics["flag.isPro"] = UserDefaults.standard.bool(forKey: SubscriptionManager.isPremiumCacheKey) ? 1 : 0
        metrics["flag.madeOwnMix"] = userMade.isEmpty ? 0 : 1
        metrics["flag.usedTimer"] = tracker.timerSessionCount > 0 ? 1 : 0
        metrics["flag.effectsMuted"] = UserDefaults.standard.bool(forKey: "effectsMuted") ? 1 : 0
        metrics["flag.favoritesOnly"] = UserDefaults.standard.bool(forKey: "favoritesOnlyPlayback") ? 1 : 0

        return metrics
    }

    // MARK: - 진단 (이 기기)

    /// **이 설치가 지금 무엇을 보내고 있는지.** 네트워크를 타지 않고 로컬 상태만 읽는다.
    ///
    /// 허브 통계는 CloudKit 스키마 배포와 read 권한이 갖춰져야 보이는데, 그 전까지는
    /// "수집이 도는지"조차 확인할 방법이 없다. 이 카드가 그 구멍을 메운다 —
    /// 지표가 0으로만 차 있으면 배선이 끊긴 것이고, 값이 차 있는데 허브가 비면 권한 문제다.
    struct Diagnostics {
        /// 익명 설치 UUID. 허브에서 내 레코드를 찾을 때 쓴다.
        let installID: String
        /// 지금 이 순간 수집이 도는지 (로컬 스위치 ∧ 원격 플래그).
        let isReportingAllowed: Bool
        /// 로컬 스위치로 꺼 둔 상태인지.
        let localSwitchOff: Bool
        /// 원격 플래그를 한 번이라도 받아봤는지. false 면 "켬"이라는 안전 기본값으로 도는 중이다.
        let remoteFlagFetched: Bool
        /// 마지막으로 설치 스냅샷을 올린 시각 (12시간 쓰로틀).
        let lastSnapshotAt: Date?
        /// 지금 보내면 나갈 지표 원본.
        let metrics: [String: Double]
        /// 이벤트별 마지막 전송 시각. 값이 없으면 아직 한 번도 안 나간 이벤트다.
        let eventLastSent: [(name: String, at: Date?)]
    }

    /// LeeoKit 이 캐시를 두는 UserDefaults 키. **LeeoKit 내부 규약을 그대로 읽는다** —
    /// 진단용이라 어긋나도 앱 동작에는 영향이 없고, 화면에 "모름"으로 나타난다.
    private static var leeoSnapshotKey: String {
        let config = DalbitSpec.feedback
        return "leeo.usage.lastSnapshotAt.\(config.containerIdentifier).\(config.appIdentifier ?? "-")"
    }
    private static var leeoFlagCacheKey: String {
        "leeo.flag." + DalbitFlag.usageReportingEnabled.rawValue
    }

    static func diagnostics() -> Diagnostics {
        let defaults = UserDefaults.standard
        return Diagnostics(
            installID: reporter.installID,
            isReportingAllowed: isReportingAllowed,
            localSwitchOff: defaults.bool(forKey: "dalbit.usage.disabled"),
            remoteFlagFetched: defaults.object(forKey: leeoFlagCacheKey) != nil,
            lastSnapshotAt: defaults.object(forKey: leeoSnapshotKey) as? Date,
            metrics: currentMetrics(),
            eventLastSent: allEventNames.map { name in
                (name, defaults.object(forKey: "dalbit.usage.lastSent." + name) as? Date)
            }
        )
    }

    // MARK: - 조회 (개발자 통계 화면용)

    typealias Snapshot = LeeoUsageReporter.UsageSnapshot

    static func fetchSnapshots(limit: Int = 1000) async throws -> [Snapshot] {
        try await reporter.fetchSnapshots(limit: limit)
    }

    /// 이벤트 이름별 집계 결과.
    struct EventStat: Identifiable, Sendable {
        let name: String
        let count: Int
        /// 그 이벤트를 남긴 서로 다른 설치 수.
        let installs: Int
        let lastAt: Date?
        var id: String { name }
    }

    /// 이벤트 1건 (차트용 원본 표본).
    struct EventSample: Sendable {
        let name: String
        let installID: String?
        let date: Date
    }

    /// 최근 이벤트를 원본 표본 그대로 읽는다 — 이름별 집계와 기간별 차트가 이 하나를 함께 쓴다.
    /// LeeoKit 은 스냅샷 조회만 제공해서 이벤트 스트림은 여기서 직접 읽는다.
    /// ⚠️ 남의 레코드를 읽으므로 컨테이너 read 권한이 필요하다(피드백 인박스와 동일).
    static func fetchEvents(limit: Int = 3000) async throws -> [EventSample] {
        let config = DalbitSpec.feedback
        let database = CKContainer(identifier: config.containerIdentifier).publicCloudDatabase

        // 허브 전체를 읽고 appId 는 클라이언트에서 거른다 — appId Queryable 인덱스 없이 동작하게.
        let query = CKQuery(recordType: LeeoUsageReporter.eventType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var samples: [EventSample] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let page: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
            if let cursor {
                page = try await database.records(continuingMatchFrom: cursor,
                                                  resultsLimit: min(200, limit - samples.count))
            } else {
                page = try await database.records(matching: query, resultsLimit: min(200, limit))
            }

            for record in page.matchResults.compactMap({ try? $0.1.get() }) {
                guard config.appIdentifier == nil || (record["appId"] as? String) == config.appIdentifier else { continue }
                // creationDate 는 서버가 "쓴 시각"으로 찍는다 — 실제 발생 시각을 우선 본다.
                let occurredAt = (record["occurredAt"] as? Date) ?? record.creationDate ?? Date()
                samples.append(EventSample(name: (record["event"] as? String) ?? "-",
                                           installID: record["installID"] as? String,
                                           date: occurredAt))
            }
            cursor = page.queryCursor
        } while cursor != nil && samples.count < limit

        return samples
    }

    /// 표본 → 이름별 집계 (화면 계산용, 네트워크 없음).
    static func eventStats(from samples: [EventSample]) -> [EventStat] {
        var counts: [String: (count: Int, installs: Set<String>, lastAt: Date?)] = [:]
        for sample in samples {
            var entry = counts[sample.name] ?? (0, [], nil)
            entry.count += 1
            if let install = sample.installID { entry.installs.insert(install) }
            if (entry.lastAt ?? .distantPast) < sample.date { entry.lastAt = sample.date }
            counts[sample.name] = entry
        }
        return counts
            .map { EventStat(name: $0.key, count: $0.value.count, installs: $0.value.installs.count, lastAt: $0.value.lastAt) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - 기간별 추이

    enum BucketUnit: String, CaseIterable, Identifiable {
        case day, week, month
        var id: String { rawValue }

        var calendarComponent: Calendar.Component {
            switch self {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            }
        }

        var localizedName: String {
            switch self {
            case .day: return L.Stats.unitDay.localized
            case .week: return L.Stats.unitWeek.localized
            case .month: return L.Stats.unitMonth.localized
            }
        }
    }

    /// 한 묶음(하루/한 주/한 달)의 집계값.
    struct TrendPoint: Identifiable, Sendable {
        let date: Date
        /// 그 기간에 활동한 서로 다른 설치 수.
        let activeInstalls: Int
        /// 그 기간에 잠든 것으로 보이는 세션을 남긴 설치 수.
        let sleepInstalls: Int
        /// 그 기간에 처음 설치된 수.
        let newInstalls: Int
        var id: Date { date }
    }

    static func trend(unit: BucketUnit,
                      events: [EventSample],
                      snapshots: [Snapshot],
                      calendar: Calendar = .current,
                      now: Date = Date()) -> [TrendPoint] {
        trend(unit: unit,
              events: events,
              installDates: snapshots.map(\.installDate),
              calendar: calendar,
              now: now)
    }

    /// 빈 구간까지 채운 연속 추이를 만든다 — 차트가 끊기지 않도록.
    ///
    /// ⚠️ 스냅샷에서 쓰는 값은 설치일뿐이라 그것만 받는다 — `UsageSnapshot` 은 CKRecord
    ///    전용 생성자뿐이어서, 그대로 받으면 유닛 테스트로 검증할 수 없다
    ///    (`UsageInsights.weeklyRetention` 과 같은 이유로 한 겹 분리한다).
    static func trend(unit: BucketUnit,
                      events: [EventSample],
                      installDates: [Date?],
                      calendar: Calendar = .current,
                      now: Date = Date()) -> [TrendPoint] {
        func bucketStart(_ date: Date) -> Date? {
            calendar.dateInterval(of: unit.calendarComponent, for: date)?.start
        }

        var activeByBucket: [Date: Set<String>] = [:]
        var sleepByBucket: [Date: Set<String>] = [:]
        for sample in events {
            guard let start = bucketStart(sample.date), let install = sample.installID else { continue }
            if sample.name == appOpenEvent { activeByBucket[start, default: []].insert(install) }
            if sample.name == sleepSessionEvent { sleepByBucket[start, default: []].insert(install) }
        }

        var newInstalls: [Date: Int] = [:]
        for installDate in installDates {
            guard let installDate, let start = bucketStart(installDate) else { continue }
            newInstalls[start, default: 0] += 1
        }

        let starts = Set(activeByBucket.keys).union(sleepByBucket.keys).union(newInstalls.keys)
        guard let first = starts.min(), let today = bucketStart(now) else { return [] }
        let last = max(starts.max() ?? today, today)

        var points: [TrendPoint] = []
        var cursor = first
        while cursor <= last && points.count < 400 {
            points.append(TrendPoint(date: cursor,
                                     activeInstalls: activeByBucket[cursor]?.count ?? 0,
                                     sleepInstalls: sleepByBucket[cursor]?.count ?? 0,
                                     newInstalls: newInstalls[cursor] ?? 0))
            guard let next = calendar.date(byAdding: unit.calendarComponent, value: 1, to: cursor) else { break }
            cursor = next
        }
        return points
    }

    /// 허브에 접수된 이 앱의 피드백 (최신순). 통계 화면 요약용.
    static func fetchFeedback(limit: Int = 100) async throws -> [LeeoFeedbackService.FeedbackRecord] {
        try await LeeoFeedbackService(spec: DalbitSpec.self).fetchAll(limit: limit)
    }
}
