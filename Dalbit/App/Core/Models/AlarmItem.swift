//
//  AlarmItem.swift
//  Dalbit
//
//  알람 시계 기능(AlarmKit) - 알람 1건을 나타내는 모델
//

import Foundation

/// 사용자가 설정한 알람 1건.
/// AlarmKit에 등록할 때 `id`를 그대로 alarm id로 사용한다.
struct AlarmItem: Identifiable, Codable, Hashable {

    /// AlarmKit alarm id 와 동일하게 사용
    let id: UUID

    /// 울릴 시각 (시 0~23)
    var hour: Int

    /// 울릴 시각 (분 0~59)
    var minute: Int

    /// 반복할 요일. 비어 있으면 1회성(가장 가까운 해당 시각 1번).
    var repeatDays: Set<Weekday>

    /// 알람음으로 사용할 앱 번들 사운드 파일명 (예: "SingingBowl.mp3"). nil이면 시스템 기본음.
    var soundFileName: String?

    /// 사용자가 붙인 라벨 (예: "기상")
    var label: String

    /// 알람 활성화 여부
    var isEnabled: Bool

    init(id: UUID = UUID(),
         hour: Int,
         minute: Int,
         repeatDays: Set<Weekday> = [],
         soundFileName: String? = nil,
         label: String = "",
         isEnabled: Bool = true) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.soundFileName = soundFileName
        self.label = label
        self.isEnabled = isEnabled
    }

    /// "07:30" 형태의 표시 문자열
    var timeText: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// 1회성 알람인지 여부
    var isOneShot: Bool { repeatDays.isEmpty }

    // MARK: - 요일

    /// 알람 반복에 사용하는 요일. rawValue는 `Calendar`의 weekday(1=일 ~ 7=토)와 동일.
    enum Weekday: Int, Codable, CaseIterable, Hashable, Comparable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7

        static func < (lhs: Weekday, rhs: Weekday) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        /// 짧은 요일 라벨 (현재 로케일 기준 자동 번역: 한국어 "월", 영어 "M" 등)
        var shortLabel: String {
            // veryShortWeekdaySymbols는 1=일요일 기준 0-index 배열
            let symbols = Calendar.current.veryShortWeekdaySymbols
            let idx = rawValue - 1
            return symbols.indices.contains(idx) ? symbols[idx] : ""
        }
    }
}
