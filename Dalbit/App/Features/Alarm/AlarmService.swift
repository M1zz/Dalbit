//
//  AlarmService.swift
//  Dalbit
//
//  알람 시계 기능(AlarmKit) - 알람 등록/취소/영속화를 담당하는 싱글톤.
//
//  코어 우선 구현: 시스템 알람 등록 + 로컬 영속화까지.
//  Live Activity(Dynamic Island/잠금화면) 표현 UI는 별도 Widget Extension에서 2차로 추가한다.
//

import Foundation
import SwiftUI
import AlarmKit
import ActivityKit

/// AlarmKit 알람에 함께 저장하는 메타데이터. 현재는 비어 있어도 무방하다.
struct DalbitAlarmMetadata: AlarmMetadata {
    init() {}
}

/// 알람음으로 고를 수 있는 사운드 1개. (달빛 컨셉에 맞춘 잔잔한 사운드 큐레이션)
struct AlarmSound: Identifiable, Hashable {
    /// 표시 이름
    let name: String
    /// 번들 사운드 파일명. nil이면 시스템 기본음.
    let fileName: String?

    var id: String { fileName ?? "__default__" }

    /// 선택 가능한 알람음 목록 (첫 항목은 시스템 기본음)
    static let all: [AlarmSound] = [
        AlarmSound(name: L.Alarm.soundDefault.localized, fileName: nil),
        AlarmSound(name: L.Alarm.soundSingingBowl.localized, fileName: "SingingBowl.mp3"),
        AlarmSound(name: L.Alarm.soundTibetanBowl.localized, fileName: "TibetanBowl.mp3"),
        AlarmSound(name: L.Alarm.soundBell.localized, fileName: "Bell.mp3"),
        AlarmSound(name: L.Alarm.soundBirds.localized, fileName: "Bird.mp3"),
        AlarmSound(name: L.Alarm.soundCuckoo.localized, fileName: "Cuckoo.mp3"),
        AlarmSound(name: L.Alarm.soundLoudBowl.localized, fileName: "BowlLoud.mp3")
    ]

    /// 파일명으로 사운드를 찾는다. 없으면 기본음.
    static func named(_ fileName: String?) -> AlarmSound {
        all.first { $0.fileName == fileName } ?? all[0]
    }
}

@MainActor
final class AlarmService: ObservableObject {

    static let shared = AlarmService()

    /// 사용자가 등록한 알람 목록 (UI 바인딩용)
    @Published private(set) var alarms: [AlarmItem] = []

    /// AlarmKit 권한 상태
    @Published private(set) var isAuthorized: Bool = false

    private let manager = AlarmManager.shared
    private let storageKey = "dalbit.alarms.v1"

    private init() {
        loadFromDisk()
        refreshAuthorization()
    }

    // MARK: - 권한

    /// 현재 권한 상태를 동기화한다.
    func refreshAuthorization() {
        isAuthorized = (manager.authorizationState == .authorized)
    }

    /// 권한을 요청한다. 이미 허용돼 있으면 true, 거부면 false.
    @discardableResult
    func requestAuthorization() async -> Bool {
        switch manager.authorizationState {
        case .authorized:
            isAuthorized = true
            return true
        case .denied:
            isAuthorized = false
            return false
        case .notDetermined:
            do {
                let state = try await manager.requestAuthorization()
                isAuthorized = (state == .authorized)
                return isAuthorized
            } catch {
                isAuthorized = false
                return false
            }
        @unknown default:
            isAuthorized = false
            return false
        }
    }

    // MARK: - CRUD

    /// 알람을 추가하고(활성 상태면) 시스템에 등록한다.
    func add(_ alarm: AlarmItem) async {
        alarms.append(alarm)
        saveToDisk()
        if alarm.isEnabled {
            await schedule(alarm)
        }
    }

    /// 알람을 삭제하고 시스템 등록도 해제한다.
    func remove(_ alarm: AlarmItem) {
        cancel(alarm)
        alarms.removeAll { $0.id == alarm.id }
        saveToDisk()
    }

    /// 알람 on/off 토글.
    func setEnabled(_ enabled: Bool, for alarm: AlarmItem) async {
        guard let idx = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[idx].isEnabled = enabled
        saveToDisk()
        if enabled {
            await schedule(alarms[idx])
        } else {
            cancel(alarms[idx])
        }
    }

    // MARK: - AlarmKit 등록/해제

    /// 단일 알람을 AlarmKit에 등록한다.
    private func schedule(_ alarm: AlarmItem) async {
        // 권한이 없으면 먼저 요청
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        do {
            let title: LocalizedStringResource = alarm.label.isEmpty
                ? LocalizedStringResource(stringLiteral: L.Alarm.title.localized)
                : LocalizedStringResource(stringLiteral: alarm.label)

            let alert: AlarmPresentation.Alert
            if #available(iOS 26.1, *) {
                // iOS 26.1+ : stopButton은 시스템이 기본 제공한다.
                alert = AlarmPresentation.Alert(title: title)
            } else {
                // iOS 26.0 : stopButton 직접 지정 필요.
                let stopButton = AlarmButton(
                    text: LocalizedStringResource(stringLiteral: L.Alarm.stop.localized),
                    textColor: .white,
                    systemImageName: "alarm.fill"
                )
                alert = AlarmPresentation.Alert(title: title, stopButton: stopButton)
            }
            let presentation = AlarmPresentation(alert: alert)

            let attributes = AlarmAttributes(
                presentation: presentation,
                metadata: DalbitAlarmMetadata(),
                tintColor: Color.purple
            )

            let schedule = makeSchedule(for: alarm)
            let sound = makeSound(for: alarm)

            let configuration = AlarmManager.AlarmConfiguration(
                schedule: schedule,
                attributes: attributes,
                sound: sound
            )

            _ = try await manager.schedule(id: alarm.id, configuration: configuration)
        } catch {
            print("[AlarmService] schedule 실패: \(error)")
        }
    }

    /// 시스템 등록 해제.
    private func cancel(_ alarm: AlarmItem) {
        do {
            try manager.cancel(id: alarm.id)
        } catch {
            print("[AlarmService] cancel 실패: \(error)")
        }
    }

    // MARK: - AlarmKit 매핑 헬퍼

    /// AlarmItem → AlarmKit 스케줄.
    private func makeSchedule(for alarm: AlarmItem) -> Alarm.Schedule {
        let time = Alarm.Schedule.Relative.Time(hour: alarm.hour, minute: alarm.minute)
        let recurrence: Alarm.Schedule.Relative.Recurrence = alarm.repeatDays.isEmpty
            ? .never
            : .weekly(alarm.repeatDays.sorted().map { $0.localeWeekday })
        return .relative(.init(time: time, repeats: recurrence))
    }

    /// AlarmItem → AlarmKit 사운드. 파일명이 있으면 앱 번들 사운드, 없으면 기본음.
    private func makeSound(for alarm: AlarmItem) -> AlertConfiguration.AlertSound {
        if let name = alarm.soundFileName {
            return .named(name)
        }
        return .default
    }

    // MARK: - 영속화

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([AlarmItem].self, from: data) else {
            return
        }
        alarms = decoded
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(alarms) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - 요일 매핑

private extension AlarmItem.Weekday {
    /// AlarmKit이 사용하는 `Locale.Weekday`로 변환.
    var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }
}
