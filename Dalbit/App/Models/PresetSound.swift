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
        // MARK: - Space(첫 실행 자동재생·유지) + 우주 앰비언트 베이스 음악 (좌우 굴리기 리스트)
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
            id: "space-cinematic",
            name: "우주 시네마틱",
            category: .meditation,
            description: "웅장하게 펼쳐지는 시네마틱 우주 앰비언트",
            icon: "sparkles",
            color: "#8B7DC8",
            layers: [],
            backgroundSound: BackgroundSound.spaceCinematic.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-ambient-1",
            name: "우주 앰비언트 I",
            category: .sleep,
            description: "잔잔하게 떠다니는 우주 앰비언트",
            icon: "moon.stars.fill",
            color: "#6B5B95",
            layers: [],
            backgroundSound: BackgroundSound.spaceAmbient1.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-deep",
            name: "딥 스페이스",
            category: .sleep,
            description: "깊고 아득한 심우주의 저음 앰비언트",
            icon: "moon.zzz.fill",
            color: "#4E5A7A",
            layers: [],
            backgroundSound: BackgroundSound.spaceDeep.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-ambient-2",
            name: "우주 앰비언트 II",
            category: .meditation,
            description: "은은한 별빛처럼 흐르는 우주 앰비언트",
            icon: "moon.stars.fill",
            color: "#A79BCB",
            layers: [],
            backgroundSound: BackgroundSound.spaceAmbient2.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-cinematic-2",
            name: "우주 시네마틱 II",
            category: .focus,
            description: "웅장한 우주를 여행하는 시네마틱 사운드",
            icon: "sparkles",
            color: "#7FB2D6",
            layers: [],
            backgroundSound: BackgroundSound.spaceCinematic2.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-shuttle",
            name: "스페이스 셔틀",
            category: .focus,
            description: "우주선을 타고 떠나는 몽환적인 항해",
            icon: "airplane",
            color: "#7C7CD8",
            layers: [],
            backgroundSound: BackgroundSound.spaceShuttle.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-solar",
            name: "솔라 윈드",
            category: .meditation,
            description: "따뜻한 태양풍이 스치는 우주 앰비언트",
            icon: "sun.max.fill",
            color: "#D6B87F",
            layers: [],
            backgroundSound: BackgroundSound.spaceSolar.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-drift",
            name: "우주 표류",
            category: .sleep,
            description: "무중력 속을 천천히 떠도는 앰비언트",
            icon: "wind",
            color: "#6B5B95",
            layers: [],
            backgroundSound: BackgroundSound.spaceDrift.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-cinematic-3",
            name: "우주 시네마틱 III",
            category: .meditation,
            description: "감성적으로 물드는 시네마틱 우주 사운드",
            icon: "sparkles",
            color: "#8B7DC8",
            layers: [],
            backgroundSound: BackgroundSound.spaceCinematic3.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-ambient-3",
            name: "우주 앰비언트 III",
            category: .sleep,
            description: "고요한 심연으로 가라앉는 우주 앰비언트",
            icon: "moon.stars.fill",
            color: "#3F4A6B",
            layers: [],
            backgroundSound: BackgroundSound.spaceAmbient3.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-orbit",
            name: "오빗",
            category: .focus,
            description: "행성 궤도를 도는 듯한 리드미컬한 우주음",
            icon: "circle.dashed",
            color: "#7FB2D6",
            layers: [],
            backgroundSound: BackgroundSound.spaceOrbit.rawValue,
            backgroundVolume: 0.5
        ),

        PresetSound(
            id: "space-void",
            name: "보이드",
            category: .sleep,
            description: "끝없는 공허를 감싸는 어두운 앰비언트",
            icon: "circle.fill",
            color: "#4E5A7A",
            layers: [],
            backgroundSound: BackgroundSound.spaceVoid.rawValue,
            backgroundVolume: 0.5
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
