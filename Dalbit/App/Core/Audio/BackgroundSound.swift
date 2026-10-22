//
//  BackgroundSound.swift
//  Dalbit
//
//  배경음 카탈로그 — 파일 이름·표시 이름·색을 한곳에서 정한다.
//  재생 엔진(AudioEngineManager)과 분리해 둔다: 이건 '무엇이 있는가'이고 엔진은 '어떻게 트는가'다.
//

import SwiftUI

/// 배경음 타입
enum BackgroundSound: String, CaseIterable {
    // 자연음
    case wave = "wave"
    case rain = "rain"
    case tv = "tv"

    // 멜로디 음악
    case piano = "piano"
    case guitar = "guitar"
    case ambient = "ambient"
    case lofi = "lofi"
    case meditation = "meditation"
    case space = "space"   // 우주 앰비언트 (앱 시작 시 자동 재생)

    // 우주 앰비언트 베이스 음악 (좌우 굴리기 리스트) — 새 기본 사운드
    case spaceCinematic = "spaceCinematic"
    case spaceAmbient1 = "spaceAmbient1"
    case spaceDeep = "spaceDeep"
    case spaceAmbient2 = "spaceAmbient2"
    case spaceCinematic2 = "spaceCinematic2"
    case spaceShuttle = "spaceShuttle"
    case spaceSolar = "spaceSolar"
    case spaceDrift = "spaceDrift"
    case spaceCinematic3 = "spaceCinematic3"
    case spaceAmbient3 = "spaceAmbient3"
    case spaceOrbit = "spaceOrbit"
    case spaceVoid = "spaceVoid"

    // 브레인 마사지 (미디 조합 배경음악) — 베이스 트랙 믹스 (레거시 · 굴리기 리스트에서 제외)
    case brainmassageFull = "brainmassageFull"
    case brainmassageDeep = "brainmassageDeep"
    case brainmassageWarm = "brainmassageWarm"
    case brainmassageBright = "brainmassageBright"
    case brainmassageDrone = "brainmassageDrone"
    case brainmassageGlow = "brainmassageGlow"
    case brainmassageMidnight = "brainmassageMidnight"
    case brainmassageCeleste = "brainmassageCeleste"

    /// 기존 한국어 rawValue로 저장된 데이터 호환을 위한 매핑
    private static let legacyMapping: [String: BackgroundSound] = [
        "파도": .wave,
        "비": .rain,
        "TV 소음": .tv,
        "피아노": .piano,
        "기타": .guitar,
        "앰비언트": .ambient,
        "로파이": .lofi,
        "명상 음악": .meditation
    ]

    /// 기존 한국어 rawValue도 지원하는 초기화
    static func from(_ value: String) -> BackgroundSound? {
        return BackgroundSound(rawValue: value) ?? legacyMapping[value]
    }

    var displayName: String {
        switch self {
        case .wave: return L.Background.wave.localized
        case .rain: return L.Background.rain.localized
        case .tv: return L.Background.tv.localized
        case .piano: return L.Background.piano.localized
        case .guitar: return L.Background.guitar.localized
        case .ambient: return L.Background.ambient.localized
        case .lofi: return L.Background.lofi.localized
        case .meditation: return L.Background.meditation.localized
        case .space: return "preset_space.space.name".localized
        case .spaceCinematic: return "preset_space.space_cinematic.name".localized
        case .spaceAmbient1: return "preset_space.space_ambient_1.name".localized
        case .spaceDeep: return "preset_space.space_deep.name".localized
        case .spaceAmbient2: return "preset_space.space_ambient_2.name".localized
        case .spaceCinematic2: return "preset_space.space_cinematic_2.name".localized
        case .spaceShuttle: return "preset_space.space_shuttle.name".localized
        case .spaceSolar: return "preset_space.space_solar.name".localized
        case .spaceDrift: return "preset_space.space_drift.name".localized
        case .spaceCinematic3: return "preset_space.space_cinematic_3.name".localized
        case .spaceAmbient3: return "preset_space.space_ambient_3.name".localized
        case .spaceOrbit: return "preset_space.space_orbit.name".localized
        case .spaceVoid: return "preset_space.space_void.name".localized
        case .brainmassageFull: return "background.brainmassage_full".localized
        case .brainmassageDeep: return "background.brainmassage_deep".localized
        case .brainmassageWarm: return "background.brainmassage_warm".localized
        case .brainmassageBright: return "background.brainmassage_bright".localized
        case .brainmassageDrone: return "background.brainmassage_drone".localized
        case .brainmassageGlow: return "background.brainmassage_glow".localized
        case .brainmassageMidnight: return "background.brainmassage_midnight".localized
        case .brainmassageCeleste: return "background.brainmassage_celeste".localized
        }
    }

    var fileName: String {
        switch self {
        case .wave: return "wave_10min"
        case .rain: return "rain_10min"
        case .tv: return "tv_10min"
        case .piano: return "piano_10min"
        case .guitar: return "guitar_10min"
        case .ambient: return "ambient_10min"
        case .lofi: return "lofi_10min"
        case .meditation: return "meditation_10min"
        case .space: return "space_1min"
        case .spaceCinematic: return "space_cinematic"
        case .spaceAmbient1: return "space_ambient_1"
        case .spaceDeep: return "space_deep"
        case .spaceAmbient2: return "space_ambient_2"
        case .spaceCinematic2: return "space_cinematic_2"
        case .spaceShuttle: return "space_shuttle"
        case .spaceSolar: return "space_solar"
        case .spaceDrift: return "space_drift"
        case .spaceCinematic3: return "space_cinematic_3"
        case .spaceAmbient3: return "space_ambient_3"
        case .spaceOrbit: return "space_orbit"
        case .spaceVoid: return "space_void"
        case .brainmassageFull: return "brainmassage_full"
        case .brainmassageDeep: return "brainmassage_deep"
        case .brainmassageWarm: return "brainmassage_warm"
        case .brainmassageBright: return "brainmassage_bright"
        case .brainmassageDrone: return "brainmassage_drone"
        case .brainmassageGlow: return "brainmassage_glow"
        case .brainmassageMidnight: return "brainmassage_midnight"
        case .brainmassageCeleste: return "brainmassage_celeste"
        }
    }

    var icon: String {
        switch self {
        case .wave: return "water.waves"
        case .rain: return "cloud.rain.fill"
        case .tv: return "tv.fill"
        case .piano: return "pianokeys"
        case .guitar: return "guitars.fill"
        case .ambient: return "waveform"
        case .lofi: return "music.note.list"
        case .meditation: return "sparkles"
        case .space: return "moon.stars.fill"
        case .spaceCinematic, .spaceCinematic2, .spaceCinematic3: return "sparkles"
        case .spaceAmbient1, .spaceAmbient2, .spaceAmbient3: return "moon.stars.fill"
        case .spaceDeep: return "moon.zzz.fill"
        case .spaceShuttle: return "airplane"
        case .spaceSolar: return "sun.max.fill"
        case .spaceDrift: return "wind"
        case .spaceOrbit: return "circle.dashed"
        case .spaceVoid: return "circle.fill"
        case .brainmassageFull: return "brain.head.profile"
        case .brainmassageDeep: return "moon.zzz.fill"
        case .brainmassageWarm: return "flame.fill"
        case .brainmassageBright: return "sun.max.fill"
        case .brainmassageDrone: return "waveform.path"
        case .brainmassageGlow: return "sparkle"
        case .brainmassageMidnight: return "moon.stars.fill"
        case .brainmassageCeleste: return "star.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .wave:
            return [
                Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.15),
                Color(red: 0.1, green: 0.5, blue: 0.9).opacity(0.1)
            ]
        case .rain:
            return [
                Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.15),
                Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.1)
            ]
        case .tv:
            return [
                Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.15),
                Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.1)
            ]
        case .piano:
            return [
                Color(red: 0.8, green: 0.6, blue: 0.9).opacity(0.15),
                Color(red: 0.7, green: 0.5, blue: 0.8).opacity(0.1)
            ]
        case .guitar:
            return [
                Color(red: 0.9, green: 0.7, blue: 0.5).opacity(0.15),
                Color(red: 0.8, green: 0.6, blue: 0.4).opacity(0.1)
            ]
        case .ambient:
            return [
                Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.15),
                Color(red: 0.4, green: 0.6, blue: 0.8).opacity(0.1)
            ]
        case .lofi:
            return [
                Color(red: 0.9, green: 0.5, blue: 0.6).opacity(0.15),
                Color(red: 0.8, green: 0.4, blue: 0.5).opacity(0.1)
            ]
        case .meditation:
            return [
                Color(red: 0.6, green: 0.8, blue: 0.7).opacity(0.15),
                Color(red: 0.5, green: 0.7, blue: 0.6).opacity(0.1)
            ]
        case .space, .spaceCinematic, .spaceAmbient1, .spaceDeep, .spaceAmbient2,
             .spaceCinematic2, .spaceShuttle, .spaceSolar, .spaceDrift,
             .spaceCinematic3, .spaceAmbient3, .spaceOrbit, .spaceVoid:
            return [
                Color(red: 0.45, green: 0.45, blue: 0.85).opacity(0.15),
                Color(red: 0.30, green: 0.30, blue: 0.60).opacity(0.1)
            ]
        case .brainmassageFull, .brainmassageDeep, .brainmassageWarm, .brainmassageBright,
             .brainmassageDrone, .brainmassageGlow, .brainmassageMidnight, .brainmassageCeleste:
            return [
                Color(red: 0.50, green: 0.42, blue: 0.80).opacity(0.15),
                Color(red: 0.32, green: 0.28, blue: 0.58).opacity(0.10)
            ]
        }
    }

    var isMelodic: Bool {
        switch self {
        case .wave, .rain, .tv:
            return false
        case .piano, .guitar, .ambient, .lofi, .meditation, .space,
             .spaceCinematic, .spaceAmbient1, .spaceDeep, .spaceAmbient2, .spaceCinematic2,
             .spaceShuttle, .spaceSolar, .spaceDrift, .spaceCinematic3, .spaceAmbient3,
             .spaceOrbit, .spaceVoid,
             .brainmassageFull, .brainmassageDeep, .brainmassageWarm, .brainmassageBright,
             .brainmassageDrone, .brainmassageGlow, .brainmassageMidnight, .brainmassageCeleste:
            return true
        }
    }
}
