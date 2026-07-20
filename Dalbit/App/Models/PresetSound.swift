//
//  PresetSound.swift
//  RelaxOn
//
//  Created by Claude on 2025/01/17.
//

import Foundation
import SwiftUI

/**
 미리 만들어진 프리셋 사운드
 사용자가 바로 사용할 수 있는 추천 사운드 조합
 */
struct PresetSound: Identifiable, Codable {
    let id: String
    let name: String
    let category: PresetCategory
    let description: String
    let icon: String
    let color: String
    let layers: [PresetLayer]
    let backgroundSound: String?
    let backgroundVolume: Float?

    struct PresetLayer: Codable {
        let filter: AudioFilter
        let category: SoundCategory
        let volume: Float
        let pitch: Float
        let interval: Float
        let intervalVariation: Float
        let volumeVariation: Float
        let pitchVariation: Float
    }

    /// 로컬라이제이션된 이름
    var localizedName: String {
        switch id {
        // 순수 미디 음원
        case "midi-piano": return L.PresetMidi.Piano.name.localized
        case "midi-lofi": return L.PresetMidi.Lofi.name.localized
        case "midi-meditation": return L.PresetMidi.Meditation.name.localized
        case "deep-sleep": return L.PresetNew.DeepSleep.name.localized
        case "rain-sleep": return L.PresetNew.RainSleep.name.localized
        case "white-noise-sleep": return L.PresetNew.WhiteNoiseSleep.name.localized
        case "cafe-focus": return L.PresetNew.CafeFocus.name.localized
        case "deep-focus": return L.PresetNew.DeepFocus.name.localized
        case "study-time": return L.PresetNew.StudyTime.name.localized
        case "meditation": return L.PresetNew.MeditationTime.name.localized
        case "yoga-stretch": return L.PresetNew.YogaStretching.name.localized
        case "forest-walk": return L.PresetNew.ForestWalk.name.localized
        case "cave-exploration": return L.PresetNew.CaveExplore.name.localized
        case "campfire": return L.Listen.campfire.localized
        case "rain": return L.Listen.rainSound.localized
        case "heavy-rain": return L.Listen.heavyRain.localized
        // 새 프리셋
        case "soft-rain": return L.PresetNew.SoftRain.name.localized
        case "city-rain": return L.PresetNew.CityRain.name.localized
        case "underwater-meditation": return L.PresetNew.UnderwaterMeditation.name.localized
        case "cosmic-atmosphere": return L.PresetNew.CosmicAtmosphere.name.localized
        case "typing-focus": return L.PresetNew.TypingFocus.name.localized
        case "camera-asmr": return L.PresetNew.CameraASMR.name.localized
        case "tibetan-meditation": return L.PresetNew.TibetanMeditation.name.localized
        case "jungle-morning": return L.PresetNew.JungleMorning.name.localized
        case "spring-forest": return L.PresetNew.SpringForest.name.localized
        default: return name
        }
    }

    /// 로컬라이제이션된 설명
    var localizedDescription: String {
        switch id {
        // 순수 미디 음원
        case "midi-piano": return L.PresetMidi.Piano.description.localized
        case "midi-lofi": return L.PresetMidi.Lofi.description.localized
        case "midi-meditation": return L.PresetMidi.Meditation.description.localized
        case "deep-sleep": return L.PresetNew.DeepSleep.description.localized
        case "rain-sleep": return L.PresetNew.RainSleep.description.localized
        case "white-noise-sleep": return L.PresetNew.WhiteNoiseSleep.description.localized
        case "cafe-focus": return L.PresetNew.CafeFocus.description.localized
        case "deep-focus": return L.PresetNew.DeepFocus.description.localized
        case "study-time": return L.PresetNew.StudyTime.description.localized
        case "meditation": return L.PresetNew.MeditationTime.description.localized
        case "yoga-stretch": return L.PresetNew.YogaStretching.description.localized
        case "forest-walk": return L.PresetNew.ForestWalk.description.localized
        case "cave-exploration": return L.PresetNew.CaveExplore.description.localized
        case "campfire": return L.Listen.campfireDescription.localized
        case "rain": return L.Listen.rainSoundDescription.localized
        case "heavy-rain": return L.Listen.heavyRainDescription.localized
        // 새 프리셋
        case "soft-rain": return L.PresetNew.SoftRain.description.localized
        case "city-rain": return L.PresetNew.CityRain.description.localized
        case "underwater-meditation": return L.PresetNew.UnderwaterMeditation.description.localized
        case "cosmic-atmosphere": return L.PresetNew.CosmicAtmosphere.description.localized
        case "typing-focus": return L.PresetNew.TypingFocus.description.localized
        case "camera-asmr": return L.PresetNew.CameraASMR.description.localized
        case "tibetan-meditation": return L.PresetNew.TibetanMeditation.description.localized
        case "jungle-morning": return L.PresetNew.JungleMorning.description.localized
        case "spring-forest": return L.PresetNew.SpringForest.description.localized
        default: return description
        }
    }
}

enum PresetCategory: String, CaseIterable, Codable {
    case sleep = "sleep"
    case focus = "focus"
    case meditation = "meditation"
    case nature = "nature"
    case rain = "rain"

    var displayName: String {
        switch self {
        case .sleep: return L.PresetCategory.sleep.localized
        case .focus: return L.PresetCategory.focus.localized
        case .meditation: return L.PresetCategory.meditation.localized
        case .nature: return L.PresetCategory.nature.localized
        case .rain: return L.PresetCategory.rain.localized
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.stars.fill"
        case .focus: return "brain.head.profile"
        case .meditation: return "leaf.fill"
        case .nature: return "tree.fill"
        case .rain: return "cloud.rain.fill"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return Color(.PrimaryPurple)
        case .focus: return .orange
        case .meditation: return .green
        case .nature: return .brown
        case .rain: return .blue
        }
    }
}

// MARK: - Preset Data

extension PresetSound {
    static let allPresets: [PresetSound] = [
        // MARK: - Space(첫 실행 자동재생·유지) + 브레인 마사지 미디 조합 (좌우 굴리기 리스트)
        PresetSound(
            id: "space",
            name: "우주",
            category: .meditation,
            description: "앱을 열면 흐르는 잔잔한 우주 앰비언트",
            icon: "moon.stars.fill",
            color: "#7C7CD8",
            layers: [],
            backgroundSound: BackgroundSound.space.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "bm-full",
            name: "브레인 마사지",
            category: .meditation,
            description: "여덟 겹의 미디 패드가 겹친 가장 풍성한 기본 조합",
            icon: "brain.head.profile",
            color: "#8B7DC8",
            layers: [
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0),
            PresetLayer(filter: .SparkleBells, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageFull.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-deep",
            name: "딥 슬립",
            category: .sleep,
            description: "저음 드론과 베이스로 깊은 수면을 유도",
            icon: "moon.zzz.fill",
            color: "#6B5B95",
            layers: [
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.45, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageDeep.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-warm",
            name: "웜 하모니",
            category: .meditation,
            description: "따뜻한 중음 하모니의 포근한 울림",
            icon: "flame.fill",
            color: "#C99DA3",
            layers: [
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0),
            PresetLayer(filter: .SparkleBells, category: .Ambient, volume: 0.45, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageWarm.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-bright",
            name: "브라이트",
            category: .focus,
            description: "맑은 중고음과 반짝임으로 산뜻하게",
            icon: "sun.max.fill",
            color: "#7FB2D6",
            layers: [
            PresetLayer(filter: .SparkleBells, category: .Ambient, volume: 0.55, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0),
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageBright.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-drone",
            name: "미니멀 드론",
            category: .sleep,
            description: "드론과 베이스만 남긴 가장 미니멀한 배경",
            icon: "waveform.path",
            color: "#4E5A7A",
            layers: [
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.4, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageDrone.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-glow",
            name: "글로우",
            category: .meditation,
            description: "은은한 패드 위로 반짝이는 벨",
            icon: "sparkle",
            color: "#D6B87F",
            layers: [
            PresetLayer(filter: .SparkleBells, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageGlow.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-midnight",
            name: "미드나잇",
            category: .sleep,
            description: "벨 없이 어둡고 잔잔한 한밤의 결",
            icon: "moon.stars.fill",
            color: "#3F4A6B",
            layers: [
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.45, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageMidnight.rawValue,
            backgroundVolume: 0.6
        ),

        PresetSound(
            id: "bm-celeste",
            name: "셀레스트",
            category: .meditation,
            description: "고음 하모니와 반짝임의 천상의 조합",
            icon: "star.fill",
            color: "#A79BCB",
            layers: [
            PresetLayer(filter: .SparkleBells, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0),
            PresetLayer(filter: .AirShimmer, category: .Ambient, volume: 0.5, pitch: 0, interval: 0, intervalVariation: 0, volumeVariation: 0, pitchVariation: 0)
        ],
            backgroundSound: BackgroundSound.brainmassageCeleste.rawValue,
            backgroundVolume: 0.6
        )
    ]

    /// 카테고리별로 프리셋을 그룹화
    static func groupedByCategory() -> [PresetCategory: [PresetSound]] {
        Dictionary(grouping: allPresets, by: { $0.category })
    }

    /// PresetSound를 CustomSound로 변환
    func toCustomSound() -> CustomSound {
        // 효과음 레이어가 없는 순수 배경음악(미디 음원) 프리셋
        if layers.isEmpty {
            return CustomSound(
                title: localizedName,
                category: .none,
                variation: AudioVariation(),
                filter: .none,
                color: color,
                backgroundSound: backgroundSound,
                backgroundVolume: backgroundVolume,
                soundLayers: nil,
                isPreset: true
            )
        }

        let soundLayers = layers.map { layer in
            CustomSound.SoundLayer(
                category: layer.category,
                filter: layer.filter,
                audioVariation: AudioVariation(
                    volume: layer.volume,
                    pitch: layer.pitch,
                    interval: layer.interval,
                    intervalVariation: layer.intervalVariation,
                    volumeVariation: layer.volumeVariation,
                    pitchVariation: layer.pitchVariation
                )
            )
        }

        return CustomSound(
            title: localizedName,
            category: layers[0].category,
            variation: AudioVariation(
                volume: layers[0].volume,
                pitch: layers[0].pitch,
                interval: layers[0].interval,
                intervalVariation: layers[0].intervalVariation,
                volumeVariation: layers[0].volumeVariation,
                pitchVariation: layers[0].pitchVariation
            ),
            filter: layers[0].filter,
            color: color,
            backgroundSound: backgroundSound,
            backgroundVolume: backgroundVolume,
            soundLayers: soundLayers.count > 1 ? soundLayers : nil,
            isPreset: true
        )
    }
}
