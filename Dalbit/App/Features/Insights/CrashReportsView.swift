//
//  CrashReportsView.swift
//  Dalbit
//
//  안정성 — LeeoDiagnostics(MetricKit)가 허브에 올린 크래시·멈춤 진단을 읽어 본다.
//  개발자 전용(설정 → 앱 버전 7번 탭).
//
//  수집만 하고 볼 곳이 없으면 반쪽이다. 여기서 답해야 하는 질문은 하나다:
//  **"이번 버전에서 크래시가 늘었나?"** 그래서 버전별 건수를 맨 위에 두고 상세는 그 아래에 둔다.
//
//  ⚠️ MetricKit 페이로드는 iOS 가 **하루 한 번꼴로 묶어서** 준다 — 방금 난 크래시는 여기 없다.
//  ⚠️ 시뮬레이터에서는 거의 올라오지 않는다. 실기기 + 사용자 규모가 있어야 쌓인다.
//  ⚠️ 남의 레코드를 읽으므로 컨테이너 read 권한이 필요하다(피드백 인박스·사용 통계와 동일).
//

import SwiftUI
import LeeoKit

struct CrashReportsView: View {

    @State private var reports: [LeeoCrashReport] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var expandedID: String?
    @State private var copiedID: String?

    /// 버전별 묶음 — 최신 버전이 위로 온다.
    private struct VersionRow: Identifiable {
        let version: String
        let crashes: Int
        let hangs: Int
        let others: Int
        var id: String { version }
        var total: Int { crashes + hangs + others }
    }

    private var versionRows: [VersionRow] {
        Dictionary(grouping: reports, by: \.appVersion)
            .map { version, items in
                VersionRow(version: version,
                           crashes: items.filter { $0.kind == "crash" }.count,
                           hangs: items.filter { $0.kind == "hang" }.count,
                           others: items.filter { $0.kind != "crash" && $0.kind != "hang" }.count)
            }
            // 버전 문자열을 숫자 순서로 비교한다 — 사전순이면 4.10 이 4.9 보다 앞에 온다.
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
    }

    var body: some View {
        ZStack {
            StarryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    if isLoading && reports.isEmpty {
                        InsightLoadingRow()
                    } else {
                        if let errorMessage { InsightErrorBanner(errorMessage) }
                        versionSection()
                        recentSection()
                    }
                    InsightFootnote(L.Stability.delayNote.localized)
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.vertical, DS.Spacing.md)
            }
            .dsConstrainedWidth()
        }
        .navigationTitle(L.Stability.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    // MARK: - 데이터

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            reports = try await LeeoDiagnosticsReader.fetch(spec: DalbitSpec.self)
            errorMessage = nil
        } catch {
            errorMessage = L.Stability.loadError.localized
        }
    }

    // MARK: - 버전별

    @ViewBuilder
    private func versionSection() -> some View {
        InsightCard(L.Stability.byVersion.localized, note: L.Stability.byVersionNote.localized) {
            if versionRows.isEmpty {
                InsightEmptyRow(L.Stability.empty.localized)
            } else {
                ForEach(versionRows) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.version)
                            .font(DS.Font.subhead().weight(.semibold))
                            .foregroundColor(DS.Colors.textPrimary)
                        Spacer()
                        // 크래시와 멈춤을 나눠 보여준다 — 대응 우선순위가 다르다.
                        Text(breakdown(row))
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textSecondary)
                        Text(String(format: L.Stability.countFormat.localized, row.total))
                            .font(DS.Font.headline())
                            .foregroundColor(row.crashes > 0 ? DS.Colors.danger : DS.Colors.textPrimary)
                            .frame(minWidth: 56, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func breakdown(_ row: VersionRow) -> String {
        var parts: [String] = []
        if row.crashes > 0 { parts.append("\(L.Stability.kindCrash.localized) \(row.crashes)") }
        if row.hangs > 0 { parts.append("\(L.Stability.kindHang.localized) \(row.hangs)") }
        if row.others > 0 { parts.append("\(L.Stability.kindDiskWrite.localized) \(row.others)") }
        return parts.joined(separator: " · ")
    }

    // MARK: - 최근 진단

    @ViewBuilder
    private func recentSection() -> some View {
        InsightCard(L.Stability.recent.localized, note: nil) {
            if reports.isEmpty {
                InsightEmptyRow(L.Stability.empty.localized)
            } else {
                ForEach(reports) { report in
                    reportRow(report)
                    if report.id != reports.last?.id { InsightDivider() }
                }
            }
        }
    }

    @ViewBuilder
    private func reportRow(_ report: LeeoCrashReport) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Button {
                withAnimation { expandedID = (expandedID == report.id) ? nil : report.id }
            } label: {
                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DS.Spacing.xs) {
                            Text(kindLabel(report.kind))
                                .font(DS.Font.subhead().weight(.semibold))
                                .foregroundColor(report.kind == "crash" ? DS.Colors.danger : DS.Colors.textPrimary)
                            Text(report.appVersion)
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        Text("\(report.deviceType) · iOS \(report.osVersion)")
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textTertiary)
                        if let createdAt = report.createdAt {
                            Text(DateFormatter.localizedString(from: createdAt,
                                                               dateStyle: .medium, timeStyle: .short))
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.textTertiary)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: expandedID == report.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if expandedID == report.id {
                if !report.detail.isEmpty, report.detail != "-" {
                    Text(report.detail)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textSecondary)
                }

                // 콜스택은 길고 줄바꿈이 없다 — 가로 스크롤로 두어야 본문 레이아웃이 깨지지 않는다.
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(report.stack.isEmpty ? "-" : report.stack)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(DS.Colors.textSecondary)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 220)

                Button {
                    UIPasteboard.general.string = copyText(report)
                    copiedID = report.id
                } label: {
                    Label(copiedID == report.id ? L.Stability.copied.localized
                                                : L.Stability.copy.localized,
                          systemImage: copiedID == report.id ? "checkmark" : "doc.on.doc")
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DS.Spacing.xxs)
    }

    /// 붙여넣기용 본문.
    /// ⚠️ 화면에 보이는 것과 **같은 것**을 담는다 — 복사한 글이 화면보다 적으면
    ///    결국 스크린샷을 다시 찍게 된다.
    private func copyText(_ report: LeeoCrashReport) -> String {
        var lines = ["[\(kindLabel(report.kind))] \(report.appVersion)"]
        if let createdAt = report.createdAt {
            lines.append(DateFormatter.localizedString(from: createdAt,
                                                       dateStyle: .medium, timeStyle: .short))
        }
        lines.append("\(report.deviceType) · iOS \(report.osVersion)")
        if !report.detail.isEmpty, report.detail != "-" { lines.append(report.detail) }
        lines.append("")
        lines.append(report.stack)
        return lines.joined(separator: "\n")
    }

    private func kindLabel(_ kind: String) -> String {
        switch kind {
        case "crash": return L.Stability.kindCrash.localized
        case "hang": return L.Stability.kindHang.localized
        case "disk_write": return L.Stability.kindDiskWrite.localized
        default: return kind
        }
    }

    // MARK: - 조각들

}
