//
//  UsageStatsView.swift
//  Dalbit
//
//  개발자 전용(설정 → 앱 버전 7번 탭) — 공용 허브(FeedbackHub)에서 실제 데이터를 읽어
//  "달빛이 값을 하고 있는가"를 한 화면에서 확인한다.
//   ① 효용 — 재워 준 시간·잠든 세션·타이머 완주율 (이 화면의 존재 이유)
//   ② 세션 길이 분포 — 짧은 쪽이 두꺼우면 소리가 안 맞은 것
//   ③ 사용자 수·활성 추이 · 리텐션 코호트
//   ④ 조합 제작 분포 · 제품 신호 · 결제 퍼널
//   ⑤ 접수된 피드백 · 안정성(크래시) 요약 → 각 상세 화면으로 이동
//   ⑥ 이 기기 진단 — 허브가 비어 있을 때 원인을 가르는 카드(맨 아래)
//
//  ⚠️ 남의 레코드를 읽는 화면이라 CloudKit 컨테이너 read 권한이 필요하다(피드백 인박스와 동일).
//  ⚠️ 개발자만 보는 화면이지만 **지역화한다** — 앱 안에서 한국어와 영어가 섞이지 않게 하려는 것이다.
//     (지표 키 이름과 이벤트 이름은 예외다. 그건 허브에 올라가는 원본이라 번역하면 안 된다.)
//

import SwiftUI
import Charts
import LeeoKit

struct UsageStatsView: View {

    @State private var snapshots: [UsageReportingService.Snapshot] = []
    @State private var eventSamples: [UsageReportingService.EventSample] = []
    @State private var feedback: [LeeoFeedbackService.FeedbackRecord] = []
    @State private var crashes: [LeeoCrashReport] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var bucketUnit: UsageReportingService.BucketUnit = .day

    /// 이 기기의 로컬 상태. 새로고침할 때마다 다시 읽어야 값이 갱신된다.
    @State private var diagnostics = UsageReportingService.diagnostics()

    private var evidence: UsageInsights.SleepEvidence {
        UsageInsights.sleepEvidence(snapshots: snapshots)
    }
    private var events: [UsageReportingService.EventStat] {
        UsageReportingService.eventStats(from: eventSamples)
    }

    var body: some View {
        ZStack {
            StarryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    if let errorMessage { InsightErrorBanner(errorMessage) }

                    if isLoading && snapshots.isEmpty && eventSamples.isEmpty {
                        InsightLoadingRow()
                    } else {
                        evidenceSection()
                        rhythmSection()
                        hourSection()
                        sessionLengthSection()
                        trendSection()
                        retentionSection()
                        mixSection()
                        signalSection()
                        funnelSection()
                        eventSection()
                        crashSection()
                        feedbackSection()
                    }

                    // 맨 아래 — 매일 보는 건 위쪽 효용 지표이고, 이 카드는 "숫자가 안 보일 때"
                    // 원인을 가르러 오는 곳이다. 네트워크를 타지 않아 로딩 중에도 그려진다.
                    diagnosticsSection()
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.vertical, DS.Spacing.md)
            }
            .dsConstrainedWidth()
        }
        .navigationTitle(L.Stats.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    // MARK: - 데이터

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        // 네트워크와 무관하므로 허브 조회가 전부 실패해도 이 값은 늘 최신이다.
        diagnostics = UsageReportingService.diagnostics()

        // 하나가 실패해도(예: 스키마 미배포) 나머지는 그대로 보여준다.
        var failures: [String] = []
        do { snapshots = try await UsageReportingService.fetchSnapshots() }
        catch { failures.append(L.Stats.sourceSnapshots.localized) }
        do { eventSamples = try await UsageReportingService.fetchEvents() }
        catch { failures.append(L.Stats.sourceEvents.localized) }
        do { feedback = try await UsageReportingService.fetchFeedback() }
        catch { failures.append(L.Stats.sourceFeedback.localized) }
        do { crashes = try await LeeoDiagnosticsReader.fetch(spec: DalbitSpec.self, limit: 200) }
        catch { failures.append(L.Stability.title.localized) }

        errorMessage = failures.isEmpty ? nil
            : String(format: L.Stats.loadFailFormat.localized, failures.joined(separator: " · "))
    }

    // MARK: - ⓪ 이 기기 (허브가 비어 있어도 보인다)

    /// **허브 스키마가 배포되기 전에도 동작하는 유일한 카드.**
    /// 위쪽 카드들이 전부 비어 있을 때 원인이 "안 보내고 있다"인지 "못 읽고 있다"인지를
    /// 여기서 가른다 — 지표가 0뿐이면 배선이 끊긴 것이고, 값이 차 있는데 위가 비면 권한 문제다.
    @ViewBuilder
    private func diagnosticsSection() -> some View {
        let d = diagnostics
        InsightCard(L.Stats.deviceTitle.localized, note: L.Stats.deviceNote.localized) {
            HStack(spacing: DS.Spacing.xs) {
                Circle()
                    .fill(d.isReportingAllowed ? DS.Colors.accent : DS.Colors.danger)
                    .frame(width: 8, height: 8)
                Text(reportingStatusText(d))
                    .font(DS.Font.subhead())
                    .foregroundColor(DS.Colors.textPrimary)
            }

            metricGrid([
                (L.Stats.lastSnapshot.localized,
                 d.lastSnapshotAt.map(relative) ?? L.Stats.lastSnapshotNone.localized,
                 L.Stats.lastSnapshotHint.localized),
                (L.Stats.metricsCount.localized,
                 String(format: L.Stats.countFormat.localized, d.metrics.count),
                 L.Stats.metricsCountHint.localized)
            ])

            InsightDivider()

            // 이벤트별 마지막 전송 — "정의만 하고 배선을 안 한" 이벤트를 여기서 잡는다.
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                ForEach(d.eventLastSent, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textSecondary)
                        Spacer(minLength: DS.Spacing.md)
                        Text(item.at.map(relative) ?? "—")
                            .font(DS.Font.caption())
                            .foregroundColor(item.at == nil ? DS.Colors.textTertiary : DS.Colors.textPrimary)
                    }
                }
            }

            InsightDivider()

            // 지표 원본 — 이름을 그대로 보여준다. 사람이 읽을 이름으로 바꾸지 않는다:
            // 여기서 확인해야 하는 건 "허브에 올라갈 키와 값"이지 예쁜 이름이 아니다.
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                ForEach(d.metrics.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textSecondary)
                        Spacer(minLength: DS.Spacing.md)
                        Text(formatMetric(d.metrics[key] ?? 0))
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                }
            }

            InsightFootnote(String(format: L.Stats.installIDFormat.localized, d.installID))
        }
    }

    private func reportingStatusText(_ d: UsageReportingService.Diagnostics) -> String {
        if d.localSwitchOff { return L.Stats.reportingOffLocal.localized }
        if !d.isReportingAllowed { return L.Stats.reportingOffRemote.localized }
        return d.remoteFlagFetched ? L.Stats.reportingOn.localized
                                   : L.Stats.reportingOnDefault.localized
    }

    // MARK: - ① 효용

    @ViewBuilder
    private func evidenceSection() -> some View {
        let e = evidence
        InsightCard(L.Stats.evidenceTitle.localized, note: L.Stats.evidenceNote.localized) {
            // 재워 준 시간 — 클립키보드의 "아낀 시간"에 해당하는, 이 앱의 대표 수치.
            headline(value: formatHours(e.totalHours), caption: L.Stats.totalHours.localized)

            metricGrid([
                (L.Stats.listeners.localized, "\(e.listeners)/\(e.installs)",
                 String(format: L.Stats.reachFormat.localized, percent(e.listenerRate))),
                (L.Stats.perListener.localized,
                 String(format: L.Stats.minutesFormat.localized, Int(e.minutesPerListener)),
                 L.Stats.perListenerHint.localized),
                (L.Stats.sleepSessions.localized, "\(e.sleepSessions)",
                 String(format: L.Stats.sleepHintFormat.localized, percent(e.sleepRate), e.sessions)),
                (L.Stats.timerCompletion.localized, percent(e.timerCompletionRate),
                 String(format: L.Stats.ofCountFormat.localized, e.timerCompleted, e.timerSessions)),
                (L.Stats.nightUse.localized, percent(e.nightRate), L.Stats.nightHint.localized),
                (L.Stats.bounce.localized, percent(e.bounceRate), L.Stats.bounceHint.localized)
            ])

            InsightFootnote(L.Stats.evidenceFootnote.localized)
        }
    }

    // MARK: - ①-2 사용 시간·빈도

    /// 효용 카드가 "여태 얼마나 값을 했나"라면 이 카드는 **"지금도 값을 하고 있나"**다.
    /// 앱이 죽어 가는 중에도 누적 수치는 계속 늘어나므로, 최근 창을 따로 봐야 한다.
    @ViewBuilder
    private func rhythmSection() -> some View {
        let r = UsageInsights.rhythm(snapshots: snapshots)
        InsightCard(L.Stats.rhythmTitle.localized, note: L.Stats.rhythmNote.localized) {
            if snapshots.isEmpty {
                InsightEmptyRow(L.Stats.snapshotEmpty.localized)
            } else {
                headline(value: percent(r.weeklyActiveRate), caption: L.Stats.weeklyActive.localized)

                metricGrid([
                    (L.Stats.weeklyActive.localized, "\(r.active7)/\(r.installs)",
                     L.Stats.weeklyActiveHint.localized),
                    (L.Stats.monthlyActive.localized, "\(r.active30)/\(r.installs)",
                     percent(r.monthlyActiveRate)),
                    (L.Stats.minutesPerActive.localized,
                     String(format: L.Stats.minutesFormat.localized, Int(r.minutesPerActive7)),
                     L.Stats.minutesPerActiveHint.localized),
                    (L.Stats.daysPerWeek.localized,
                     String(format: L.Stats.daysFormat.localized, r.daysPerWeek),
                     L.Stats.daysPerWeekHint.localized),
                    (L.Stats.sessionsPerDay.localized,
                     String(format: L.Stats.timesFormat.localized, r.sessionsPerActiveDay),
                     L.Stats.sessionsPerDayHint.localized),
                    (L.Stats.daysIdle.localized,
                     String(format: L.Stats.daysFormat.localized, r.medianDaysIdle),
                     L.Stats.daysIdleHint.localized),
                    (L.Stats.bestStreak.localized,
                     String(format: L.Stats.daysFormat.localized, r.averageBestStreak),
                     L.Stats.bestStreakHint.localized)
                ])

                InsightFootnote(L.Stats.rhythmFootnote.localized)
            }
        }
    }

    // MARK: - ①-3 시간대 분포

    @ViewBuilder
    private func hourSection() -> some View {
        let buckets = UsageInsights.hourDistribution(snapshots: snapshots)
        InsightCard(L.Stats.hourTitle.localized, note: L.Stats.hourNote.localized) {
            if buckets.allSatisfy({ $0.count == 0 }) {
                InsightEmptyRow(L.Stats.lengthEmpty.localized)
            } else {
                Chart(buckets) { bucket in
                    BarMark(x: .value(L.Stats.axisHour.localized, bucket.label),
                            y: .value(L.Stats.axisSessions.localized, bucket.count))
                        // 밤(20시 이후·새벽 4시 이전)은 이 앱이 노리는 시간대라 색으로 구분한다.
                        .foregroundStyle(bucket.order == 0 || bucket.order == 5
                                         ? DS.Colors.warm : DS.Colors.accent)
                }
                .chartXAxis { AxisMarks(preset: .aligned) }
                .frame(height: 150)
            }
        }
    }

    // MARK: - ② 세션 길이 분포

    @ViewBuilder
    private func sessionLengthSection() -> some View {
        let buckets = UsageInsights.sessionLengths(snapshots: snapshots)
        let total = buckets.reduce(0) { $0 + $1.count }
        InsightCard(L.Stats.lengthTitle.localized, note: L.Stats.lengthNote.localized) {
            if total == 0 {
                InsightEmptyRow(L.Stats.lengthEmpty.localized)
            } else {
                Chart(buckets) { bucket in
                    BarMark(x: .value(L.Stats.axisLength.localized, bucket.label),
                            y: .value(L.Stats.axisSessions.localized, bucket.count))
                        .foregroundStyle(DS.Colors.accent)
                        .annotation(position: .top) {
                            Text("\(bucket.count)")
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.textTertiary)
                        }
                }
                .chartXAxis { AxisMarks { AxisValueLabel().font(DS.Font.caption()) } }
                .frame(height: 180)
            }
        }
    }

    // MARK: - ③ 추이 · 리텐션

    @ViewBuilder
    private func trendSection() -> some View {
        let points = UsageReportingService.trend(unit: bucketUnit,
                                                 events: eventSamples,
                                                 snapshots: snapshots)
        InsightCard(L.Stats.trendTitle.localized, note: L.Stats.trendNote.localized) {
            Picker(L.Stats.unitPicker.localized, selection: $bucketUnit) {
                ForEach(UsageReportingService.BucketUnit.allCases) { unit in
                    Text(unit.localizedName).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            if points.isEmpty {
                InsightEmptyRow(L.Stats.trendEmpty.localized)
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(x: .value(L.Stats.axisPeriod.localized, point.date),
                                 y: .value(L.Stats.axisActive.localized, point.activeInstalls),
                                 series: .value(L.Stats.axisSeries.localized, L.Stats.axisActive.localized))
                            .foregroundStyle(DS.Colors.accent)
                        LineMark(x: .value(L.Stats.axisPeriod.localized, point.date),
                                 y: .value(L.Stats.axisSlept.localized, point.sleepInstalls),
                                 series: .value(L.Stats.axisSeries.localized, L.Stats.axisSlept.localized))
                            .foregroundStyle(DS.Colors.warm)
                    }
                }
                .frame(height: 180)

                HStack(spacing: DS.Spacing.md) {
                    legend(color: DS.Colors.accent, label: L.Stats.legendActive.localized)
                    legend(color: DS.Colors.warm, label: L.Stats.legendSlept.localized)
                }
            }
        }
    }

    @ViewBuilder
    private func retentionSection() -> some View {
        let rows = UsageInsights.weeklyRetention(snapshots: snapshots, events: eventSamples)
        InsightCard(L.Stats.retentionTitle.localized, note: L.Stats.retentionNote.localized) {
            if rows.isEmpty {
                InsightEmptyRow(L.Stats.retentionEmpty.localized)
            } else {
                ForEach(rows.prefix(8)) { row in
                    HStack {
                        Text(row.cohortStart, format: .dateTime.month().day())
                            .font(DS.Font.subhead().weight(.semibold))
                            .foregroundColor(DS.Colors.textPrimary)
                            .frame(width: 64, alignment: .leading)
                        Text(String(format: L.Stats.peopleFormat.localized, row.size))
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textTertiary)
                            .frame(width: 44, alignment: .leading)
                        Spacer()
                        retentionCell("D1", row.rate(row.day1))
                        retentionCell("D7", row.rate(row.day7))
                        retentionCell("D30", row.rate(row.day30))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func retentionCell(_ label: String, _ rate: Double) -> some View {
        VStack(spacing: 1) {
            Text(percent(rate))
                .font(DS.Font.subhead().weight(.semibold))
                .foregroundColor(rate > 0 ? DS.Colors.textPrimary : DS.Colors.textTertiary)
            Text(label)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
        }
        .frame(width: 48)
    }

    // MARK: - ④ 조합 · 신호 · 퍼널

    @ViewBuilder
    private func mixSection() -> some View {
        let buckets = UsageInsights.mixDistribution(snapshots: snapshots)
        let total = buckets.reduce(0) { $0 + $1.count }
        InsightCard(L.Stats.mixTitle.localized, note: L.Stats.mixNote.localized) {
            if total == 0 {
                InsightEmptyRow(L.Stats.snapshotEmpty.localized)
            } else {
                Chart(buckets) { bucket in
                    BarMark(x: .value(L.Stats.axisMixCount.localized, bucket.label),
                            y: .value(L.Stats.axisInstalls.localized, bucket.count))
                        .foregroundStyle(bucket.isFreeLimit ? DS.Colors.warm : DS.Colors.accent)
                }
                .chartXAxis { AxisMarks { AxisValueLabel().font(DS.Font.caption()) } }
                .frame(height: 160)
                InsightFootnote(L.Stats.mixFootnote.localized)
            }
        }
    }

    @ViewBuilder
    private func signalSection() -> some View {
        let signals = UsageInsights.signals(snapshots: snapshots)
        InsightCard(L.Stats.signalTitle.localized, note: nil) {
            if signals.isEmpty {
                InsightEmptyRow(L.Stats.snapshotEmpty.localized)
            } else {
                ForEach(signals) { signal in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(signal.name)
                                .font(DS.Font.subhead().weight(.semibold))
                                .foregroundColor(DS.Colors.textPrimary)
                            Spacer()
                            Text(signal.value)
                                .font(DS.Font.subhead().weight(.bold))
                                .foregroundColor(DS.Colors.accent)
                        }
                        Text(signal.hint)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textTertiary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    @ViewBuilder
    private func funnelSection() -> some View {
        let stages = UsageInsights.paywallFunnel(from: eventSamples)
        InsightCard(L.Stats.funnelTitle.localized, note: L.Stats.funnelNote.localized) {
            ForEach(stages) { stage in
                HStack {
                    Text(stage.name)
                        .font(DS.Font.subhead())
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    Text("\(stage.installs)")
                        .font(DS.Font.subhead().weight(.semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                    Text(percent(stage.rateFromTop))
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                        .frame(width: 48, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func eventSection() -> some View {
        InsightCard(L.Stats.eventTitle.localized, note: L.Stats.eventNote.localized) {
            if events.isEmpty {
                InsightEmptyRow(L.Stats.eventEmpty.localized)
            } else {
                ForEach(events) { event in
                    HStack {
                        Text(event.name)
                            .font(DS.Font.subhead())
                            .foregroundColor(DS.Colors.textPrimary)
                        Spacer()
                        Text(String(format: L.Stats.peopleFormat.localized, event.installs))
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textTertiary)
                        Text("\(event.count)")
                            .font(DS.Font.subhead().weight(.semibold))
                            .foregroundColor(DS.Colors.textPrimary)
                            .frame(width: 48, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - ⑤ 안정성 (크래시·멈춤)

    /// 여기서는 **건수와 최신 버전만** 보여주고 상세는 안정성 화면으로 넘긴다 —
    /// 이 화면의 주제는 효용이고, 크래시는 "지금 봐야 하나"만 판단하면 된다.
    @ViewBuilder
    private func crashSection() -> some View {
        InsightCard(L.Stability.title.localized, note: nil) {
            NavigationLink(destination: CrashReportsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(crashes.isEmpty
                             ? L.Stability.empty.localized
                             : String(format: L.Stability.countFormat.localized, crashes.count))
                            .font(DS.Font.subhead().weight(.semibold))
                            .foregroundColor(crashes.contains { $0.kind == "crash" }
                                             ? DS.Colors.danger : DS.Colors.textPrimary)
                        if let latest = crashes.first {
                            Text("\(latest.appVersion) · \(latest.deviceType)")
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.textTertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - ⑥ 피드백

    @ViewBuilder
    private func feedbackSection() -> some View {
        let pending = feedback.filter { !$0.isDone }
        InsightCard(L.Stats.feedbackTitle.localized, note: nil) {
            NavigationLink(destination: FeedbackInboxView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: L.Stats.feedbackCountFormat.localized, feedback.count, pending.count))
                            .font(DS.Font.subhead().weight(.semibold))
                            .foregroundColor(DS.Colors.textPrimary)
                        if let latest = feedback.first {
                            Text(latest.message)
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.textTertiary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 조각들

    @ViewBuilder
    private func headline(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(DS.Font.largeTitle())
                .foregroundColor(DS.Colors.accent)
            Text(caption)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
        }
    }

    @ViewBuilder
    private func metricGrid(_ items: [(String, String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Spacing.md, alignment: .leading),
                            GridItem(.flexible(), alignment: .leading)],
                  spacing: DS.Spacing.lg) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.0)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                    Text(item.1)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Colors.textPrimary)
                    Text(item.2)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                        .opacity(0.8)
                }
            }
        }
    }

    @ViewBuilder
    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
        }
    }

    // MARK: - 포맷

    private func percent(_ ratio: Double) -> String {
        String(format: "%.0f%%", ratio * 100)
    }

    /// "3시간 전" 같은 상대 시각 — 진단 카드에서는 절대 시각보다 이쪽이 판단이 빠르다.
    /// (지금 보낸 건지, 어제 것인지만 알면 된다.)
    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// 지표 원본 값. 개수는 정수로, 소수가 붙은 값만 소수점을 남긴다.
    private func formatMetric(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }

    /// 누적 시간 — 100시간이 넘으면 소수점을 버린다(자릿수가 길어지면 읽기 어렵다).
    private func formatHours(_ hours: Double) -> String {
        if hours < 1 { return String(format: L.Stats.minutesFormat.localized, Int(hours * 60)) }
        if hours < 100 { return String(format: L.Stats.hoursDecimalFormat.localized, hours) }
        return String(format: L.Stats.hoursFormat.localized, Int(hours))
    }
}
