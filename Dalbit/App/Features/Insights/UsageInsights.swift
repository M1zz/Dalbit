//
//  UsageInsights.swift
//  Dalbit
//
//  "달빛이 실제로 재우고 있는가"를 **이미 쌓고 있는 지표만으로** 계산한다.
//  새 수집 항목을 늘리지 않는다(수집이 늘면 개인정보 부담도 같이 는다).
//
//  근거
//   효용   — UsageSnapshot.metrics 의 listenMin / sessions / sleepSessions / timer* / len*
//   퍼널   — UsageEvent 의 paywall_view → paywall_purchase
//   코호트 — UsageSnapshot.installDate(가입일) + `app_open` 이벤트(활동일)
//
//  ⚠️ 전부 **순수 함수**다. 네트워크·CloudKit 을 모르기 때문에 유닛 테스트가 가능하고,
//     화면(UsageStatsView)은 이미 받아온 표본을 넘겨주기만 하면 된다.
//  ⚠️ "잠들었다"는 **추정**이다(타이머 완주 + 30분 이상 방치 종료). 수면을 측정한 값이
//     아니므로 화면에서도 추정이라고 밝혀야 한다. 판정 기준은 ListeningTracker 참고.
//

import Foundation

enum UsageInsights {

    // MARK: - 효용 (이 화면의 존재 이유)

    /// 이 앱이 값을 하고 있는지를 한 판에 보여주는 수치들.
    struct SleepEvidence {
        /// 스냅샷을 올린 전체 설치 수.
        let installs: Int
        /// 그중 소리를 한 번이라도 들은 설치 수.
        let listeners: Int
        /// 누적 청취 시간(시간).
        let totalHours: Double
        /// 들은 사람 1명당 평균 청취 시간(분).
        let minutesPerListener: Double
        /// 끝난 세션 총합.
        let sessions: Int
        /// 그중 잠든 것으로 보이는 세션.
        let sleepSessions: Int
        /// 밤(22~04시)에 시작한 세션.
        let nightSessions: Int
        /// 5분을 못 채우고 끝난 세션.
        let shortSessions: Int
        /// 수면 타이머를 건 세션과 그중 끝까지 간 세션.
        let timerSessions: Int
        let timerCompleted: Int

        /// 설치하고 실제로 소리까지 들은 비율 — **온보딩 성패를 가장 잘 보여주는 숫자**.
        /// 깔았는데 재생을 안 했다면 이 앱의 가치를 아직 한 번도 받지 못한 것이다.
        var listenerRate: Double { installs > 0 ? Double(listeners) / Double(installs) : 0 }

        /// 잠든 것으로 보이는 세션의 비율 — 이 앱이 제 일을 한 비율.
        var sleepRate: Double { sessions > 0 ? Double(sleepSessions) / Double(sessions) : 0 }

        /// 밤에 쓰인 비율 — 낮게 나오면 수면 앱이 아니라 집중/작업용으로 쓰이고 있다는 뜻이고,
        /// 그렇다면 스토어 문구와 기능의 무게중심을 옮겨야 한다.
        var nightRate: Double { sessions > 0 ? Double(nightSessions) / Double(sessions) : 0 }

        /// 5분을 못 넘긴 비율 — **이 앱의 진짜 실패율**이다.
        /// 열었는데 금방 껐다는 건 그 사람에게 맞는 소리를 못 찾아 줬다는 뜻이다.
        var bounceRate: Double { sessions > 0 ? Double(shortSessions) / Double(sessions) : 0 }

        /// 타이머 완주율 — 끄지 않고 끝까지 갔다는, 잠들었다는 가장 믿을 만한 신호.
        var timerCompletionRate: Double {
            timerSessions > 0 ? Double(timerCompleted) / Double(timerSessions) : 0
        }
    }

    static func sleepEvidence(snapshots: [UsageReportingService.Snapshot]) -> SleepEvidence {
        sleepEvidence(metrics: snapshots.map(\.metrics))
    }

    /// ⚠️ 지표 딕셔너리만 받는다 — `UsageSnapshot` 은 CKRecord 전용 생성자뿐이라
    ///    그대로 받으면 유닛 테스트로 검증할 수 없다.
    static func sleepEvidence(metrics snapshots: [[String: Double]]) -> SleepEvidence {
        func total(_ key: String) -> Int {
            snapshots.reduce(0) { $0 + Int($1[key] ?? 0) }
        }
        let totalMinutes = snapshots.reduce(0.0) { $0 + ($1["listenMin"] ?? 0) }
        let listeners = snapshots.filter { ($0["listenMin"] ?? 0) > 0 }.count

        return SleepEvidence(
            installs: snapshots.count,
            listeners: listeners,
            totalHours: totalMinutes / 60,
            minutesPerListener: listeners > 0 ? totalMinutes / Double(listeners) : 0,
            sessions: total("sessions"),
            sleepSessions: total("sleepSessions"),
            nightSessions: total("nightSessions"),
            shortSessions: total("len0"),
            timerSessions: total("timerSessions"),
            timerCompleted: total("timerCompleted")
        )
    }

    // MARK: - 사용 시간·빈도

    /// **지금** 얼마나 자주, 얼마나 오래 쓰이고 있는가.
    ///
    /// 누적 합계(`효용` 카드)와 일부러 나눠 둔다 — 누적은 "여태 얼마나 값을 했나"를 말하고,
    /// 이쪽은 "지금도 값을 하고 있나"를 말한다. 앱이 죽어 가는 중에도 누적은 계속 늘어난다.
    struct Rhythm {
        /// 최근 7일에 한 번이라도 들은 설치 수. 이 무리 안에서만 아래 평균이 의미가 있다.
        let active7: Int
        let active30: Int
        /// 스냅샷을 올린 전체 설치 수.
        let installs: Int

        /// 최근 7일 청취 분 합계와, 7일 활성 설치 1개당 평균.
        let minutes7: Double
        let minutes30: Double

        /// 7일 중 들은 날 수의 평균(활성 설치 기준). 7에 가까울수록 매일 쓰는 것이다.
        let daysPerWeek: Double
        /// 들은 날 하루당 세션 수 — 하루에 몇 번 트는가.
        let sessionsPerActiveDay: Double
        /// 마지막 청취로부터 지난 일수의 중앙값(한 번이라도 들은 설치 기준).
        let medianDaysIdle: Double
        /// 역대 최장 연속일의 평균.
        let averageBestStreak: Double

        /// 최근 7일에 들은 비율 — 이 앱의 주간 활성 사용자 비율.
        var weeklyActiveRate: Double { installs > 0 ? Double(active7) / Double(installs) : 0 }
        var monthlyActiveRate: Double { installs > 0 ? Double(active30) / Double(installs) : 0 }
        /// 7일 활성 1인당 평균 청취 분.
        var minutesPerActive7: Double { active7 > 0 ? minutes7 / Double(active7) : 0 }
    }

    static func rhythm(snapshots: [UsageReportingService.Snapshot]) -> Rhythm {
        rhythm(metrics: snapshots.map(\.metrics))
    }

    static func rhythm(metrics snapshots: [[String: Double]]) -> Rhythm {
        func sum(_ key: String) -> Double { snapshots.reduce(0) { $0 + ($1[key] ?? 0) } }

        let active7 = snapshots.filter { ($0["activeDays7"] ?? 0) > 0 }
        let active30 = snapshots.filter { ($0["activeDays30"] ?? 0) > 0 }

        // 들은 날이 0인 설치까지 분모에 넣으면 평균이 바닥으로 눌려 아무것도 안 보인다.
        let daysPerWeek = active7.isEmpty ? 0
            : active7.reduce(0.0) { $0 + ($1["activeDays7"] ?? 0) } / Double(active7.count)

        let activeDayTotal = sum("activeDays30")
        let sessionsPerActiveDay = activeDayTotal > 0 ? sum("sessions30") / activeDayTotal : 0

        // 평균이 아니라 **중앙값**이다 — 오래 안 연 설치 몇 개가 평균을 통째로 끌고 간다.
        let idle = snapshots.compactMap { $0["daysIdle"] }.sorted()
        let medianDaysIdle: Double = idle.isEmpty ? 0
            : (idle.count % 2 == 1 ? idle[idle.count / 2]
                                   : (idle[idle.count / 2 - 1] + idle[idle.count / 2]) / 2)

        let withStreak = snapshots.filter { ($0["bestStreak"] ?? 0) > 0 }
        let averageBestStreak = withStreak.isEmpty ? 0
            : withStreak.reduce(0.0) { $0 + ($1["bestStreak"] ?? 0) } / Double(withStreak.count)

        return Rhythm(active7: active7.count,
                      active30: active30.count,
                      installs: snapshots.count,
                      minutes7: sum("listenMin7"),
                      minutes30: sum("listenMin30"),
                      daysPerWeek: daysPerWeek,
                      sessionsPerActiveDay: sessionsPerActiveDay,
                      medianDaysIdle: medianDaysIdle,
                      averageBestStreak: averageBestStreak)
    }

    // MARK: - 시간대 분포

    /// 하루 중 언제 트는가 (4시간 6칸).
    /// 밤 여부 하나로는 "자기 전"과 "새벽에 깨서"가 구분되지 않는데, 그 둘은 다른 제품을 부른다.
    static func hourDistribution(snapshots: [UsageReportingService.Snapshot]) -> [DistributionBucket] {
        hourDistribution(metrics: snapshots.map(\.metrics))
    }

    static func hourDistribution(metrics snapshots: [[String: Double]]) -> [DistributionBucket] {
        (0..<ListeningTracker.hourBucketCount).map { index in
            let count = snapshots.reduce(0) { $0 + Int($1["tod\(index)"] ?? 0) }
            return DistributionBucket(label: Self.hourBucketLabel(index), count: count, order: index)
        }
    }

    /// "0–4시" 같은 구간 이름. 숫자만 쓰므로 번역이 필요 없다.
    static func hourBucketLabel(_ index: Int) -> String {
        "\(index * 4)–\((index + 1) * 4)"
    }

    // MARK: - 세션 길이 분포

    struct DistributionBucket: Identifiable {
        /// 지역화된 표시 이름.
        let label: String
        let count: Int
        /// 정렬용 순서. **식별자도 이 값이다** — 라벨은 언어에 따라 바뀌므로 id 로 쓸 수 없다.
        let order: Int
        /// 무료 한도(조합 3개)에 딱 걸린 구간인지.
        /// ⚠️ 화면이 라벨 문자열을 비교해서 이걸 알아내면 안 된다 — 번역이 바뀌는 순간 조용히 깨진다.
        var isFreeLimit = false
        var id: Int { order }
    }

    /// 세션이 얼마나 오래 갔는지 — 왼쪽(짧은 쪽)이 두꺼우면 소리가 안 맞는 것이고,
    /// 오른쪽이 두꺼우면 재우고 있다는 뜻이다. 효용 판단에서 평균보다 훨씬 많은 걸 말해 준다.
    static func sessionLengths(snapshots: [UsageReportingService.Snapshot]) -> [DistributionBucket] {
        sessionLengths(metrics: snapshots.map(\.metrics))
    }

    static func sessionLengths(metrics snapshots: [[String: Double]]) -> [DistributionBucket] {
        ListeningTracker.bucketLabelKeys.enumerated().map { index, key in
            let count = snapshots.reduce(0) { $0 + Int($1["len\(index)"] ?? 0) }
            return DistributionBucket(label: key.localized, count: count, order: index)
        }
    }

    // MARK: - 조합 제작 분포 (핵심 가치 도달)

    /// "나만의 소리를 만든다"가 이 앱의 핵심 가치인데, 정말 만드는지는 이걸 봐야 안다.
    /// 0개에 몰려 있으면 프리셋 재생기로만 쓰이고 있다는 뜻이고,
    /// 그렇다면 제작 화면이 어렵거나 프리셋만으로 충분하다는 신호다 — 어느 쪽이든 큰 결정이 걸린다.
    ///
    /// ⚠️ 무료 한도(3개) 앞뒤를 끊어 둔다 — 한도 직전에 몰려 있으면 한도가 결제를 만들고 있다는 뜻이다.
    static func mixDistribution(snapshots: [UsageReportingService.Snapshot]) -> [DistributionBucket] {
        mixDistribution(metrics: snapshots.map(\.metrics))
    }

    static func mixDistribution(metrics snapshots: [[String: Double]]) -> [DistributionBucket] {
        let bounds: [(key: String, lower: Int, upper: Int, isFreeLimit: Bool)] = [
            (L.MixBucket.zero, 0, 0, false),
            (L.MixBucket.oneTwo, 1, 2, false),
            // 무료 한도 — 여기 몰려 있으면 한도가 결제를 만들고 있다는 뜻이라 따로 끊어 둔다
            (L.MixBucket.three, 3, 3, true),
            (L.MixBucket.fourNine, 4, 9, false),
            (L.MixBucket.tenPlus, 10, .max, false)
        ]
        return bounds.enumerated().map { order, bound in
            let count = snapshots.filter { metrics in
                let n = Int(metrics["customMixes"] ?? 0)
                return n >= bound.lower && n <= bound.upper
            }.count
            return DistributionBucket(label: bound.key.localized, count: count,
                                      order: order, isFreeLimit: bound.isFreeLimit)
        }
    }

    // MARK: - 제품·마케팅 신호

    struct Signal: Identifiable {
        /// 언어와 무관한 안정적 식별자. **표시 이름을 id 로 쓰지 않는다** —
        /// 번역이 바뀌면 SwiftUI 의 뷰 동일성이 깨지고, 테스트도 언어에 묶인다.
        let id: String
        /// 지역화된 표시 이름.
        let name: String
        let value: String
        /// 이 숫자를 어떻게 읽어야 하는지 — 숫자만 있으면 판단을 못 한다.
        let hint: String
    }

    static func signals(snapshots: [UsageReportingService.Snapshot]) -> [Signal] {
        signals(metrics: snapshots.map(\.metrics))
    }

    static func signals(metrics snapshots: [[String: Double]]) -> [Signal] {
        guard !snapshots.isEmpty else { return [] }
        let n = Double(snapshots.count)

        func ratio(_ predicate: ([String: Double]) -> Bool) -> String {
            String(format: "%.0f%%", Double(snapshots.filter(predicate).count) / n * 100)
        }
        func average(_ key: String) -> String {
            String(format: "%.1f", snapshots.reduce(0.0) { $0 + ($1[key] ?? 0) } / n)
        }

        let totalMixes = snapshots.reduce(0.0) { $0 + ($1["mixes"] ?? 0) }
        let totalUnused = snapshots.reduce(0.0) { $0 + ($1["unusedMixes"] ?? 0) }
        let unusedRate = totalMixes > 0 ? totalUnused / totalMixes * 100 : 0

        return [
            Signal(id: "proRate",
                   name: L.Signal.proRate.localized,
                   value: ratio { ($0["flag.isPro"] ?? 0) > 0 },
                   hint: L.Signal.proRateHint.localized),
            Signal(id: "madeOwnMix",
                   name: L.Signal.madeOwnMix.localized,
                   value: ratio { ($0["flag.madeOwnMix"] ?? 0) > 0 },
                   hint: L.Signal.madeOwnMixHint.localized),
            Signal(id: "usedTimer",
                   name: L.Signal.usedTimer.localized,
                   value: ratio { ($0["flag.usedTimer"] ?? 0) > 0 },
                   hint: L.Signal.usedTimerHint.localized),
            Signal(id: "unusedMixes",
                   name: L.Signal.unusedMixes.localized,
                   value: String(format: "%.0f%%", unusedRate),
                   hint: L.Signal.unusedMixesHint.localized),
            Signal(id: "mixesPerInstall",
                   name: L.Signal.mixesPerInstall.localized,
                   value: average("mixes"),
                   hint: L.Signal.mixesPerInstallHint.localized),
            Signal(id: "avgStreak",
                   name: L.Signal.avgStreak.localized,
                   value: average("streakDays"),
                   hint: L.Signal.avgStreakHint.localized)
        ]
    }

    // MARK: - 전환 퍼널

    struct FunnelStage: Identifiable {
        /// 단계 순서 = 식별자. 표시 이름은 언어에 따라 바뀌므로 id 로 쓰지 않는다.
        let id: Int
        /// 지역화된 표시 이름.
        let name: String
        /// 이 단계에 도달한 서로 다른 설치 수.
        let installs: Int
        /// 첫 단계 대비 비율 (0.0 ~ 1.0).
        let rateFromTop: Double
    }

    private static func installs(in samples: [UsageReportingService.EventSample],
                                 named name: String) -> Set<String> {
        var result = Set<String>()
        for sample in samples where sample.name == name {
            if let id = sample.installID { result.insert(id) }
        }
        return result
    }

    /// 들었다 → 페이월을 봤다 → 샀다. 각 단계는 **서로 다른 설치 수** 기준이다.
    ///
    /// ⚠️ 이벤트에 6시간 쓰로틀이 걸려 있어 같은 사람이 하루에 여러 번 본 페이월은 1건이다.
    ///    절대 수치가 아니라 단계 간 비율을 보는 용도다.
    static func paywallFunnel(from samples: [UsageReportingService.EventSample]) -> [FunnelStage] {
        let steps: [(nameKey: String, event: String)] = [
            (L.Funnel.listen, UsageReportingService.listenStartEvent),
            (L.Funnel.paywall, UsageReportingService.paywallViewEvent),
            (L.Funnel.purchase, UsageReportingService.paywallPurchaseEvent)
        ]

        var topCount = 0
        return steps.enumerated().map { index, step in
            let count = installs(in: samples, named: step.event).count
            if index == 0 { topCount = count }
            return FunnelStage(id: index,
                               name: step.nameKey.localized,
                               installs: count,
                               rateFromTop: topCount > 0 ? Double(count) / Double(topCount) : 0)
        }
    }

    // MARK: - 리텐션 코호트

    struct RetentionRow: Identifiable {
        /// 설치 주 시작일 (코호트 라벨).
        let cohortStart: Date
        let size: Int
        let day1: Int
        let day7: Int
        let day30: Int
        var id: Date { cohortStart }

        func rate(_ retained: Int) -> Double { size > 0 ? Double(retained) / Double(size) : 0 }
    }

    /// 코호트 계산에 실제로 필요한 것만 담은 입력.
    /// ⚠️ `UsageSnapshot` 에 직접 의존하면 유닛 테스트로 검증할 수 없어 한 겹 분리한다.
    struct Install {
        let id: String
        let installDate: Date?
    }

    static func weeklyRetention(snapshots: [UsageReportingService.Snapshot],
                                events: [UsageReportingService.EventSample],
                                calendar: Calendar = .current,
                                now: Date = Date()) -> [RetentionRow] {
        weeklyRetention(installs: snapshots.map { Install(id: $0.id, installDate: $0.installDate) },
                        events: events, calendar: calendar, now: now)
    }

    /// 주간 코호트 리텐션.
    /// - installDate 로 코호트를 나누고, `app_open` 이벤트로 "그날 활동했는가"를 본다.
    /// - ⚠️ `app_open` 은 20시간 쓰로틀이라 하루 1건 이하다 → 날짜 단위 판정에 적합하다.
    static func weeklyRetention(installs snapshots: [Install],
                                events: [UsageReportingService.EventSample],
                                calendar: Calendar = .current,
                                now: Date = Date()) -> [RetentionRow] {

        var activeDays: [String: Set<Date>] = [:]
        for event in events where event.name == UsageReportingService.appOpenEvent {
            guard let id = event.installID else { continue }
            activeDays[id, default: []].insert(calendar.startOfDay(for: event.date))
        }

        var cohorts: [Date: [(id: String, installedAt: Date)]] = [:]
        for snapshot in snapshots {
            guard let installDate = snapshot.installDate,
                  let week = calendar.dateInterval(of: .weekOfYear, for: installDate)?.start else { continue }
            cohorts[week, default: []].append((snapshot.id, installDate))
        }

        return cohorts.map { week, members in
            /// 설치 후 `offset`일째에 활동했는지. 아직 그날이 오지 않은 설치는 잔존으로 세지 않는다.
            func retained(after offset: Int) -> Int {
                members.filter { member in
                    guard let target = calendar.date(byAdding: .day, value: offset,
                                                     to: calendar.startOfDay(for: member.installedAt)),
                          target <= now else { return false }
                    return activeDays[member.id]?.contains(target) ?? false
                }.count
            }

            return RetentionRow(cohortStart: week,
                                size: members.count,
                                day1: retained(after: 1),
                                day7: retained(after: 7),
                                day30: retained(after: 30))
        }
        .sorted { $0.cohortStart > $1.cohortStart }
    }
}
