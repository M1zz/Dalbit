//
//  ListeningTracker.swift
//  Dalbit
//
//  청취 세션 원장 — "달빛이 실제로 재우고 있는가"를 뒷받침할 수치를 로컬에 쌓는다.
//  여기서 만든 수치가 UsageReportingService 의 지표로 올라가고, 개발자 통계 화면의
//  "효용" 섹션이 그 지표만으로 계산된다.
//
//  왜 재생 시간을 세는가
//   클립키보드가 "아낀 시간"으로 효용을 증명하듯, 수면 앱의 효용은 **재워 준 시간**이다.
//   설치 수·실행 수는 사람이 앱을 열었다는 것만 말해 준다. 열고 3분 만에 끄면
//   그건 소리가 맞지 않았다는 뜻인데, 실행 수만 보면 그 실패가 성공처럼 보인다.
//
//  ⚠️ **PII 없음**: 소리 제목은 사용자가 직접 지은 이름이라(예: 아이 이름) 절대 담지 않는다.
//     이 파일이 다루는 값은 초·개수뿐이다.
//  ⚠️ 재생 중 앱이 죽는 것이 이 앱의 **정상 경로**다 — 사람이 잠들면 앱을 끄지 않는다.
//     그래서 세션 종료를 "지금"으로 닫으면 안 된다. 자세한 건 closeOrphanSession() 참고.
//

import Foundation

/// 세션이 끝난 이유 — "잠들었을 가능성"을 가르는 유일한 근거라 이유별로 따로 센다.
enum ListeningEndReason {
    /// 사용자가 직접 정지했다 — 깨어 있었다는 뜻이다.
    case userStopped
    /// 수면 타이머가 끝까지 갔다 — 중간에 끄지 않았다는 가장 강한 신호.
    case timerCompleted
    /// 타이머를 도중에 껐다 — 소리가 맞지 않았거나 볼일이 생긴 것.
    case timerCancelled
    /// 앱이 재생 중에 끝났다 — 마지막 생존 신호까지만 인정한다.
    case orphaned
}

final class ListeningTracker {

    static let shared = ListeningTracker()

    private let defaults: UserDefaults
    private let prefix = "dalbit.listen."

    /// 재생 중 60초마다 찍는 생존 신호. 앱이 죽어도 여기까지는 실제로 들은 시간이다.
    private var heartbeatTimer: Timer?
    private static let heartbeatInterval: TimeInterval = 60

    /// 타이머 없이 이만큼 재생된 채 앱이 끝났으면 잠든 것으로 본다.
    /// ⚠️ 어디까지나 **추정**이다. 화면에서도 추정이라고 밝혀야 한다.
    private static let sleepLikelyThreshold: TimeInterval = 30 * 60

    /// 한 세션 길이의 상한 — 기기 시계가 튀거나 심박 기록이 깨졌을 때 하루치가
    /// 통째로 청취 시간으로 잡히는 것을 막는 안전판.
    private static let maxSessionSeconds: TimeInterval = 12 * 3600

    /// 밤 세션으로 볼 시작 시각(현지 시간 기준). 22시~04시.
    private static let nightHours: Set<Int> = [22, 23, 0, 1, 2, 3, 4]

    /// 활동일을 보관하는 기간 — 연속일 계산에 필요한 만큼만 두고 잘라 낸다.
    private static let activeDayRetention = 90

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        closeOrphanSession()
    }

    private func key(_ k: String) -> String { prefix + k }

    // MARK: - 누적값 (읽기 전용)

    /// 누적 청취 시간(초).
    var totalSeconds: Double { defaults.double(forKey: key("totalSeconds")) }
    /// 끝난 세션 수.
    var sessionCount: Int { defaults.integer(forKey: key("sessionCount")) }
    /// 밤(22~04시)에 시작한 세션 수 — 수면 목적으로 쓰이는지의 근거.
    var nightSessionCount: Int { defaults.integer(forKey: key("nightSessions")) }
    /// 수면 타이머를 걸고 시작한 세션 수.
    var timerSessionCount: Int { defaults.integer(forKey: key("timerSessions")) }
    /// 그중 끝까지 간 세션 수.
    var timerCompletedCount: Int { defaults.integer(forKey: key("timerCompleted")) }
    /// 잠들었을 것으로 보이는 세션 수 (타이머 완주 + 30분 이상 방치 종료).
    var sleepLikelyCount: Int { defaults.integer(forKey: key("sleepLikely")) }
    /// 가장 길었던 세션(초).
    var longestSessionSeconds: Double { defaults.double(forKey: key("longestSeconds")) }

    /// 세션 길이 분포 — [5분 미만, 5~15, 15~30, 30~60, 60분 이상].
    /// 5분 미만이 두꺼우면 "열었는데 안 맞아서 껐다"는 뜻이고, 그게 이 앱의 진짜 실패다.
    var lengthBuckets: [Int] {
        let stored = defaults.array(forKey: key("buckets")) as? [Int] ?? []
        guard stored.count == Self.bucketBounds.count else {
            return Array(repeating: 0, count: Self.bucketBounds.count)
        }
        return stored
    }

    /// 분포 구간의 상한(분). 마지막 구간은 상한이 없다.
    static let bucketBounds: [Double] = [5, 15, 30, 60, .infinity]

    /// 구간 이름의 지역화 키. **키를 노출하고 문구는 화면에서 만든다** —
    /// 여기서 바로 지역화하면 앱 언어가 바뀌어도 이미 계산된 값이 옛 언어로 남는다.
    static let bucketLabelKeys = [
        L.LengthBucket.under5,
        L.LengthBucket.fiveToFifteen,
        L.LengthBucket.fifteenToThirty,
        L.LengthBucket.thirtyToSixty,
        L.LengthBucket.over60
    ]

    /// 소리를 실제로 들은 날짜(yyyy-MM-dd), 오래된 것부터.
    var activeDays: [String] {
        defaults.stringArray(forKey: key("activeDays")) ?? []
    }

    // MARK: - 일자별 원장 (사용 시간·빈도)

    /// 날짜별 청취 시간(초). 최근 `activeDayRetention` 일치만 남는다.
    ///
    /// 누적 합계만으로는 **지금 잘 쓰이고 있는지**를 알 수 없다 — 한 달 전에 몰아 듣고
    /// 그만둔 사람과 매일 조금씩 듣는 사람의 `listenMin` 이 같게 나오기 때문이다.
    /// 최근 7일·30일을 따로 볼 수 있어야 성장인지 이탈인지가 갈린다.
    var dailySeconds: [String: Double] {
        defaults.dictionary(forKey: key("dailySeconds")) as? [String: Double] ?? [:]
    }

    /// 날짜별 끝난 세션 수. "하루에 몇 번 트는가"(빈도)의 근거.
    var dailySessions: [String: Int] {
        defaults.dictionary(forKey: key("dailySessions")) as? [String: Int] ?? [:]
    }

    /// 시간대별 세션 시작 분포 — 4시간씩 6칸 (0~4, 4~8, …, 20~24시).
    /// 밤 여부(`nightSessions`)만으로는 "새벽에 깨서 트는 사람"과 "자기 전에 트는 사람"이
    /// 구분되지 않는다. 둘은 필요한 기능이 다르다.
    var hourBuckets: [Int] {
        let stored = defaults.array(forKey: key("hourBuckets")) as? [Int] ?? []
        return stored.count == Self.hourBucketCount ? stored
                                                    : Array(repeating: 0, count: Self.hourBucketCount)
    }
    static let hourBucketCount = 6

    /// 지금까지 가장 길었던 연속 청취일. 현재 줄(`currentStreak`)이 끊겨도 남는다 —
    /// "한때 습관이었는지"와 "지금 습관인지"는 다른 질문이다.
    var bestStreak: Int { defaults.integer(forKey: key("bestStreak")) }

    /// 마지막으로 들은 날로부터 지난 일수. 없으면 nil.
    /// 이탈을 가장 빨리 보여 주는 값이라 따로 둔다.
    var daysSinceLastListen: Int? {
        guard let last = activeDays.last, let date = Self.date(fromDayKey: last) else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day],
                                       from: calendar.startOfDay(for: date),
                                       to: calendar.startOfDay(for: Date())).day
    }

    /// 최근 `days` 일간(오늘 포함) 청취 분.
    func recentMinutes(days: Int, now: Date = Date()) -> Double {
        recentKeys(days: days, now: now).reduce(0.0) { $0 + (dailySeconds[$1] ?? 0) } / 60
    }

    /// 최근 `days` 일간 소리를 들은 날 수 — **사용 빈도의 핵심 지표**.
    func recentActiveDays(days: Int, now: Date = Date()) -> Int {
        let listened = Set(activeDays)
        return recentKeys(days: days, now: now).filter { listened.contains($0) }.count
    }

    /// 최근 `days` 일간 끝난 세션 수.
    func recentSessions(days: Int, now: Date = Date()) -> Int {
        let sessions = dailySessions
        return recentKeys(days: days, now: now).reduce(0) { $0 + (sessions[$1] ?? 0) }
    }

    private func recentKeys(days: Int, now: Date) -> [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today).map(Self.dayKey(for:))
        }
    }

    /// 오늘로 이어지는 연속 청취 일수. 어제까지만 들었으면 그 줄도 살아 있는 것으로 본다
    /// (오늘 밤은 아직 오지 않았다 — 자정 직후에 줄이 끊긴 것처럼 보이면 지표가 거짓말을 한다).
    var currentStreak: Int {
        let days = Set(activeDays)
        guard !days.isEmpty else { return 0 }

        let calendar = Calendar.current
        var cursor = calendar.startOfDay(for: Date())
        // 오늘 아직 안 들었으면 어제부터 센다.
        if !days.contains(Self.dayKey(for: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(Self.dayKey(for: cursor)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    // MARK: - 세션 기록

    /// 재생이 시작됐다. 이미 열린 세션이 있으면 그것부터 닫는다(곡 전환).
    /// - Parameter timerMinutes: 수면 타이머를 걸고 시작했다면 그 길이(분). 아니면 nil.
    func begin(timerMinutes: Int? = nil) {
        // ⚠️ 걸어 둔 타이머는 곡을 넘겨도 살아 있다 — 여기서 미리 챙기지 않으면 아래 end() 가
        //    지워 버려서, 자다가 곡이 한 번 넘어간 사람은 타이머를 안 쓴 것으로 집계된다.
        let carriedTimer = timerMinutes ?? currentTimerMinutes

        if openSessionStart != nil {
            // 곡을 넘긴 것이지 그만 들은 게 아니다 — 지금까지를 한 세션으로 확정하고 이어 간다.
            end(reason: .userStopped)
        }
        let now = Date()
        defaults.set(now, forKey: key("openStart"))
        defaults.set(now, forKey: key("heartbeat"))
        if let carriedTimer { defaults.set(carriedTimer, forKey: key("openTimerMin")) }

        startHeartbeat()
    }

    /// 수면 타이머를 걸었다 — 이미 재생 중인 세션에 붙는다.
    /// (타이머 화면은 소리가 이미 흐르는 상태에서 열리므로 재생 시작과 시점이 다르다)
    func attachTimer(minutes: Int) {
        defaults.set(minutes, forKey: key("openTimerMin"))
    }

    /// 현재 세션에 걸린 타이머 길이(분). 없으면 nil.
    var currentTimerMinutes: Int? {
        defaults.object(forKey: key("openTimerMin")) as? Int
    }

    /// 재생이 끝났다. 열린 세션이 없으면 아무것도 하지 않는다(중복 호출 안전).
    func end(reason: ListeningEndReason) {
        guard let start = openSessionStart else { return }
        stopHeartbeat()

        // 앱이 죽어서 닫는 경우엔 "지금"이 아니라 마지막 생존 신호까지만 인정한다.
        let endedAt = (reason == .orphaned) ? (lastHeartbeat ?? start) : Date()
        let duration = min(max(endedAt.timeIntervalSince(start), 0), Self.maxSessionSeconds)

        let timerMinutes = defaults.object(forKey: key("openTimerMin")) as? Int
        clearOpenSession()

        // 1초도 안 되는 것은 오조작이다 — 세션으로 세면 짧은 세션 비율이 거짓으로 부푼다.
        guard duration >= 1 else { return }

        bumpSeconds("totalSeconds", by: duration)
        bump("sessionCount")
        if duration > longestSessionSeconds {
            defaults.set(duration, forKey: key("longestSeconds"))
        }

        if Self.nightHours.contains(Calendar.current.component(.hour, from: start)) {
            bump("nightSessions")
        }
        if timerMinutes != nil {
            bump("timerSessions")
            if reason == .timerCompleted { bump("timerCompleted") }
        }
        if Self.isSleepLikely(reason: reason, duration: duration) {
            bump("sleepLikely")
        }

        recordBucket(for: duration)
        recordActiveDay(start)
        recordDaily(start: start, duration: duration)
        recordHourBucket(for: start)

        // 익명 허브로 올린다 — 무엇을 왜 보내는지는 UsageReportingService 머리말 참고.
        UsageReportingService.reportListeningSession(startedAt: start,
                                                     duration: duration,
                                                     reason: reason,
                                                     hadTimer: timerMinutes != nil)
    }

    /// 잠들었다고 볼 것인가.
    /// - 타이머 완주: 끝까지 끄지 않았다 → 가장 믿을 만한 신호.
    /// - 30분 이상 방치 종료: 앱이 재생 중에 끝났고 충분히 길었다.
    /// ⚠️ `userStopped`는 아무리 길어도 여기 들어오지 않는다 — 직접 껐다는 건 깨어 있었다는 뜻이다.
    static func isSleepLikely(reason: ListeningEndReason, duration: TimeInterval) -> Bool {
        switch reason {
        case .timerCompleted: return true
        case .orphaned: return duration >= sleepLikelyThreshold
        case .userStopped, .timerCancelled: return false
        }
    }

    // MARK: - 열린 세션

    private var openSessionStart: Date? {
        defaults.object(forKey: key("openStart")) as? Date
    }
    private var lastHeartbeat: Date? {
        defaults.object(forKey: key("heartbeat")) as? Date
    }
    private func clearOpenSession() {
        defaults.removeObject(forKey: key("openStart"))
        defaults.removeObject(forKey: key("heartbeat"))
        defaults.removeObject(forKey: key("openTimerMin"))
    }

    /// 지난 실행에서 재생 중에 앱이 끝났다면 그 세션을 마지막 생존 신호로 닫는다.
    ///
    /// ⚠️ 이 앱에서는 이게 **예외가 아니라 흔한 일**이다 — 사람이 잠들면 앱을 끄지 않는다.
    ///    "지금"으로 닫으면 며칠 뒤 앱을 열었을 때 그 며칠이 통째로 청취 시간이 되고,
    ///    효용 지표가 조용히 몇 배로 부풀어 오른다. 그럴 바엔 세지 않는 편이 낫다.
    private func closeOrphanSession() {
        guard openSessionStart != nil else { return }
        end(reason: .orphaned)
    }

    // MARK: - 생존 신호

    private func startHeartbeat() {
        stopHeartbeat()
        let timer = Timer(timeInterval: Self.heartbeatInterval, repeats: true) { [weak self] _ in
            guard let self, self.openSessionStart != nil else { return }
            self.defaults.set(Date(), forKey: self.key("heartbeat"))
        }
        // 스크롤·제스처 중에도 멈추지 않도록 common 모드에 넣는다.
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    // MARK: - 저장 도우미

    /// 세션 수 계열 카운터 +1.
    private func bump(_ name: String) {
        defaults.set(defaults.integer(forKey: key(name)) + 1, forKey: key(name))
    }

    /// 초 단위 누적값 — 소수점이 있어 카운터와 저장 타입이 다르다.
    private func bumpSeconds(_ name: String, by amount: Double) {
        defaults.set(defaults.double(forKey: key(name)) + amount, forKey: key(name))
    }

    private func recordBucket(for duration: TimeInterval) {
        let minutes = duration / 60
        guard let index = Self.bucketBounds.firstIndex(where: { minutes < $0 }) else { return }
        var buckets = lengthBuckets
        buckets[index] += 1
        defaults.set(buckets, forKey: key("buckets"))
    }

    private func recordActiveDay(_ date: Date) {
        let key = Self.dayKey(for: date)
        var days = activeDays
        guard !days.contains(key) else { return }
        days.append(key)
        days.sort()
        if days.count > Self.activeDayRetention {
            days.removeFirst(days.count - Self.activeDayRetention)
        }
        defaults.set(days, forKey: self.key("activeDays"))
        // 오늘 새로 기록됐으니 줄이 하루 늘었을 수 있다.
        updateBestStreak()
    }

    /// 날짜별 청취 시간·세션 수를 더한다. 보관 기간을 넘긴 날짜는 함께 잘라 낸다.
    /// ⚠️ 세션이 자정을 넘겨도 **시작한 날**에 몰아 준다 — 하루를 쪼개 나누면
    ///    "며칠에 들었나"(빈도)를 셀 때 한 번 잔 것이 이틀로 잡힌다.
    private func recordDaily(start: Date, duration: TimeInterval) {
        let day = Self.dayKey(for: start)

        var seconds = dailySeconds
        seconds[day, default: 0] += duration
        defaults.set(prune(seconds), forKey: key("dailySeconds"))

        var sessions = dailySessions
        sessions[day, default: 0] += 1
        defaults.set(prune(sessions), forKey: key("dailySessions"))
    }

    /// 보관 기간(90일)을 넘긴 날짜를 버린다 — 원장이 무한정 커지지 않게.
    private func prune<T>(_ ledger: [String: T]) -> [String: T] {
        guard ledger.count > Self.activeDayRetention else { return ledger }
        let keep = Set(ledger.keys.sorted().suffix(Self.activeDayRetention))
        return ledger.filter { keep.contains($0.key) }
    }

    private func recordHourBucket(for start: Date) {
        let hour = Calendar.current.component(.hour, from: start)
        let index = min(hour / 4, Self.hourBucketCount - 1)
        var buckets = hourBuckets
        buckets[index] += 1
        defaults.set(buckets, forKey: key("hourBuckets"))
    }

    /// 오늘까지 이어진 줄이 역대 최장이면 갱신한다.
    private func updateBestStreak() {
        let streak = currentStreak
        if streak > bestStreak { defaults.set(streak, forKey: key("bestStreak")) }
    }

    /// yyyy-MM-dd (현지 시간). 날짜 비교에만 쓰므로 고정 로캘·달력을 쓴다.
    static func dayKey(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    /// `dayKey` 의 역변환. 마지막 청취일로부터 며칠 지났는지 셀 때 쓴다.
    static func date(fromDayKey key: String) -> Date? {
        Self.dayFormatter.date(from: key)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - 테스트/디버그

    /// 모든 누적값 초기화.
    func reset() {
        stopHeartbeat()
        for k in defaults.dictionaryRepresentation().keys where k.hasPrefix(prefix) {
            defaults.removeObject(forKey: k)
        }
    }
}
