//
//  AlarmListView.swift
//  Dalbit
//
//  알람 시계 - 알람 목록 화면. 추가/토글/삭제 + 비어있을 때 안내.
//

import SwiftUI

struct AlarmListView: View {

    /// 세그먼트 페이저에 콘텐츠만 임베드되는 모드. 네비게이션 크롬을 숨기고, 추가(+)는 상위가 담당한다.
    var embedded: Bool = false
    /// embedded 모드에서 '알람 추가' 요청을 상위로 전달.
    var onRequestAdd: (() -> Void)? = nil

    @ObservedObject private var service = AlarmService.shared
    @State private var editingAlarm: AlarmItem?
    @State private var isPresentingNew = false

    var body: some View {
        ZStack {
            // embedded(타이머 페이저 안)에서는 배경을 투명하게 두어 상위의 공유 우주 별 배경이
            // 비치도록 하고, 독립 화면으로 열릴 때만 자체 배경을 그린다.
            if !embedded {
                ScreenBackground()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    if service.alarms.isEmpty {
                        emptyState()
                    } else {
                        SectionHeader(title: L.Alarm.myAlarms.localized,
                                      systemIcon: "alarm",
                                      accessory: "\(service.alarms.count)")
                        ForEach(sortedAlarms) { alarm in
                            AlarmRow(alarm: alarm,
                                     onToggle: { enabled in
                                         Task { await service.setEnabled(enabled, for: alarm) }
                                     },
                                     onTap: { editingAlarm = alarm },
                                     onDelete: { service.remove(alarm) })
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.vertical, DS.Spacing.lg)
                .dsConstrainedWidth()
            }
        }
        .navigationTitle(embedded ? "" : L.Alarm.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 일반 모드에서만 자체 + 버튼. (세그먼트 페이저에서는 상위가 추가 버튼을 그린다.)
            if !embedded {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNew = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(L.Alarm.add.localized)
                }
            }
        }
        // 새 알람 만들기
        .navigationDestination(isPresented: $isPresentingNew) {
            AlarmEditView(mode: .create)
        }
        // 기존 알람 편집
        .navigationDestination(item: $editingAlarm) { alarm in
            AlarmEditView(mode: .edit(alarm))
        }
        .onAppear { service.refreshAuthorization() }
    }

    /// 시각 순 정렬
    private var sortedAlarms: [AlarmItem] {
        service.alarms.sorted {
            ($0.hour, $0.minute) < ($1.hour, $1.minute)
        }
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "alarm")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(DS.Colors.accent)
                .accessibilityHidden(true)
            Text(L.Alarm.emptyTitle.localized)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)
            Text(L.Alarm.emptyDesc.localized)
                .font(DS.Font.subhead())
                .foregroundColor(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button(L.Alarm.add.localized) {
                if embedded { onRequestAdd?() } else { isPresentingNew = true }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            .padding(.top, DS.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxxl)
    }
}

// MARK: - Alarm Row

private struct AlarmRow: View {
    let alarm: AlarmItem
    let onToggle: (Bool) -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(alarm.timeText)
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .foregroundColor(alarm.isEnabled ? DS.Colors.textPrimary : DS.Colors.textTertiary)
                    HStack(spacing: DS.Spacing.xs) {
                        if !alarm.label.isEmpty {
                            Text(alarm.label)
                                .font(DS.Font.subhead())
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        Text(repeatText)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: onToggle))
                .labelsHidden()
                .tint(DS.Colors.accent)
        }
        .dsCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: L.Alarm.a11yRow.localized,
                                    alarm.timeText,
                                    alarm.label.isEmpty ? "" : ", \(alarm.label)",
                                    repeatText))
        .accessibilityHint(L.Alarm.rowHint.localized)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label(L.Common.delete.localized, systemImage: "trash")
            }
        }
    }

    private var repeatText: String {
        if alarm.repeatDays.isEmpty { return L.Alarm.repeatOnce.localized }
        if alarm.repeatDays.count == 7 { return L.Alarm.repeatEveryday.localized }
        let weekdays: Set<AlarmItem.Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if alarm.repeatDays == weekdays { return L.Alarm.repeatWeekdays.localized }
        if alarm.repeatDays == [.saturday, .sunday] { return L.Alarm.repeatWeekend.localized }
        return alarm.repeatDays.sorted().map { $0.shortLabel }.joined(separator: " ")
    }
}

#Preview {
    NavigationStack { AlarmListView() }
}
