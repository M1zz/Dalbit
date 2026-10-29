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
                                     onDelete: { delete(alarm) })
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
                    .accessibilityInputLabels([Text(L.Voice.addAlarm.localized), Text(L.Alarm.add.localized)])
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

    /// 알람을 지우고, 화면을 못 보는 사람에게도 지워졌다고 알린다.
    private func delete(_ alarm: AlarmItem) {
        service.remove(alarm)
        AccessibilityNotification.Announcement(
            String(format: L.Announce.alarmDeleted.localized, alarm.timeText)
        ).post()
    }

    /// 알람이 하나도 없을 때 — 시스템 빈 화면 틀(제목·설명·행동)을 그대로 따른다.
    @ViewBuilder
    private func emptyState() -> some View {
        ContentUnavailableView {
            Label {
                Text(L.Alarm.emptyTitle.localized)
                    .foregroundColor(DS.Colors.textPrimary)
            } icon: {
                Image(systemName: "alarm")
                    .foregroundColor(DS.Colors.accent)
            }
        } description: {
            Text(L.Alarm.emptyDesc.localized)
                .foregroundColor(DS.Colors.textSecondary)
        } actions: {
            Button(L.Alarm.add.localized) {
                if embedded { onRequestAdd?() } else { isPresentingNew = true }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xl)
    }
}

// MARK: - Alarm Row

private struct AlarmRow: View {
    let alarm: AlarmItem
    let onToggle: (Bool) -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    /// 큰 글씨(손쉬운 사용 크기)에서는 시각과 스위치를 한 줄에 우겨넣지 않고 위아래로 쌓는다.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 40

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DS.Spacing.sm))
            : AnyLayout(HStackLayout(spacing: DS.Spacing.md))
        layout {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(alarm.timeText)
                        .font(.system(size: timeSize, weight: .light, design: .rounded))
                        .foregroundColor(alarm.isEnabled ? DS.Colors.textPrimary : DS.Colors.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    HStack(spacing: DS.Spacing.xs) {
                        if !alarm.label.isEmpty {
                            // 사람이 붙인 이름이라 길이를 알 수 없다 — 한 줄로 두고 끝을 줄인다.
                            Text(alarm.label)
                                .font(DS.Font.subhead())
                                .foregroundColor(DS.Colors.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .allowsTightening(true)
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
            // 편집 버튼과 켜고 끄는 스위치를 따로 둔다 — 한 요소로 묶으면 두 번 탭이 어느 쪽인지
            // 알 수 없고, 켜짐 여부가 글씨 색으로만 남는다.
            .accessibilityLabel(String(format: L.Alarm.a11yRow.localized,
                                        alarm.timeText,
                                        alarm.label.isEmpty ? "" : ", \(alarm.label)",
                                        repeatText))
            .accessibilityHint(L.Alarm.rowHint.localized)
            .accessibilityAction(named: Text(L.Common.delete.localized), onDelete)

            // 화면에선 숨기지만 VoiceOver 는 "7:00, 스위치, 켬" 처럼 시각을 이름으로 읽는다.
            Toggle(alarm.timeText, isOn: Binding(get: { alarm.isEnabled }, set: onToggle))
                .labelsHidden()
                .tint(DS.Colors.accent)
        }
        .dsCard()
        // ⚠️ 이 행은 List 가 아니라 ScrollView 안에 있어서 swipeActions 가 동작하지 않았다 —
        //    지우는 길이 편집 화면밖에 없었다. 길게 눌러 지울 수 있게 메뉴를 단다.
        .contextMenu {
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
