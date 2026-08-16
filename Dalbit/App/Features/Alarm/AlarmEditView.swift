//
//  AlarmEditView.swift
//  Dalbit
//
//  알람 시계 - 알람 추가/편집 화면. 시각·반복요일·사운드·라벨을 설정한다.
//

import SwiftUI

struct AlarmEditView: View {

    enum Mode {
        case create
        case edit(AlarmItem)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = AlarmService.shared

    @State private var time: Date = AlarmEditView.defaultTime
    @State private var selectedDays: Set<AlarmItem.Weekday> = []
    @State private var soundFileName: String?
    @State private var label: String = ""

    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    timePickerCard()
                    repeatCard()
                    soundCard()
                    labelCard()

                    if case .edit(let alarm) = mode {
                        Button(role: .destructive) {
                            service.remove(alarm)
                            dismiss()
                        } label: {
                            Text(L.Alarm.delete.localized)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .tint(DS.Colors.danger)
                    }
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.vertical, DS.Spacing.lg)
                .dsConstrainedWidth()
            }
        }
        .navigationTitle(isEditing ? L.Alarm.editTitle.localized : L.Alarm.add.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L.Common.save.localized) { save() }
                    .font(DS.Font.headline())
            }
        }
        .onAppear(perform: loadInitialState)
    }

    // MARK: - Cards

    @ViewBuilder
    private func timePickerCard() -> some View {
        VStack {
            DatePicker(L.Alarm.time.localized, selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
        .dsCard()
    }

    @ViewBuilder
    private func repeatCard() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: L.Alarm.repeatTitle.localized, systemIcon: "repeat")
            HStack(spacing: DS.Spacing.xs) {
                ForEach(orderedWeekdays, id: \.self) { day in
                    Button {
                        toggleDay(day)
                    } label: {
                        Text(day.shortLabel)
                            .font(DS.Font.subhead().weight(.semibold))
                            .frame(width: 38, height: 38)
                            .foregroundColor(selectedDays.contains(day) ? DS.Colors.onAccent : DS.Colors.textSecondary)
                            .background(
                                Circle().fill(selectedDays.contains(day) ? DS.Colors.accent : DS.Colors.surfaceSunken)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(format: L.Alarm.a11yWeekday.localized, day.shortLabel))
                    .accessibilityAddTraits(selectedDays.contains(day) ? .isSelected : [])
                }
            }
            Text(repeatSummary)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    @ViewBuilder
    private func soundCard() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: L.Alarm.sound.localized, systemIcon: "speaker.wave.2")
            ForEach(AlarmSound.all) { sound in
                Button {
                    soundFileName = sound.fileName
                } label: {
                    HStack {
                        Text(sound.name)
                            .font(DS.Font.body())
                            .foregroundColor(DS.Colors.textPrimary)
                        Spacer()
                        if sound.fileName == soundFileName {
                            Image(systemName: "checkmark")
                                .font(DS.Font.subhead().weight(.semibold))
                                .foregroundColor(DS.Colors.accent)
                        }
                    }
                    .padding(.vertical, DS.Spacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(sound.fileName == soundFileName ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    @ViewBuilder
    private func labelCard() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: L.Alarm.label.localized, systemIcon: "tag")
            TextField(L.Alarm.labelPlaceholder.localized, text: $label)
                .font(DS.Font.body())
                .foregroundColor(DS.Colors.textPrimary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .fill(DS.Colors.surfaceSunken)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    // MARK: - State

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private static var defaultTime: Date {
        var comps = DateComponents()
        comps.hour = 7
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    /// 월요일부터 시작하는 표시 순서
    private var orderedWeekdays: [AlarmItem.Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }

    private var repeatSummary: String {
        if selectedDays.isEmpty { return L.Alarm.summaryOnce.localized }
        if selectedDays.count == 7 { return L.Alarm.summaryEveryday.localized }
        let weekdays: Set<AlarmItem.Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if selectedDays == weekdays { return L.Alarm.summaryWeekdays.localized }
        if selectedDays == [.saturday, .sunday] { return L.Alarm.summaryWeekend.localized }
        let days = selectedDays.sorted().map { $0.shortLabel }.joined(separator: ", ")
        return String(format: L.Alarm.summaryFormat.localized, days)
    }

    private func loadInitialState() {
        guard case .edit(let alarm) = mode else { return }
        var comps = DateComponents()
        comps.hour = alarm.hour
        comps.minute = alarm.minute
        time = Calendar.current.date(from: comps) ?? Self.defaultTime
        selectedDays = alarm.repeatDays
        soundFileName = alarm.soundFileName
        label = alarm.label
    }

    private func toggleDay(_ day: AlarmItem.Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    // MARK: - Save

    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            let newAlarm = AlarmItem(hour: hour,
                                     minute: minute,
                                     repeatDays: selectedDays,
                                     soundFileName: soundFileName,
                                     label: trimmedLabel,
                                     isEnabled: true)
            Task { await service.add(newAlarm) }

        case .edit(let original):
            // 기존 알람 교체 (제거 후 동일 id로 재등록)
            let updated = AlarmItem(id: original.id,
                                    hour: hour,
                                    minute: minute,
                                    repeatDays: selectedDays,
                                    soundFileName: soundFileName,
                                    label: trimmedLabel,
                                    isEnabled: original.isEnabled)
            Task {
                service.remove(original)
                await service.add(updated)
            }
        }
        dismiss()
    }
}

#Preview {
    NavigationStack { AlarmEditView(mode: .create) }
}
