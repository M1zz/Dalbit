//
//  SoundListView+Extension.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/25.
//

import Foundation

/// 전문가가 큐레이션한 프리셋 사운드 조합
struct Preset: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: SoundCategory
    let filter: AudioFilter
    let audioVariation: AudioVariation
    let color: String

    init(
        title: String,
        description: String,
        category: SoundCategory,
        filter: AudioFilter,
        audioVariation: AudioVariation,
        color: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.filter = filter
        self.audioVariation = audioVariation
        self.color = color ?? category.defaultColor
    }

    /// Preset을 OriginalSound로 변환
    func toOriginalSound() -> OriginalSound {
        return OriginalSound(
            name: title,
            filter: filter,
            category: category
        )
    }

    /// 전문가 큐레이션 프리셋 목록
    static let recommended: [Preset] = [
        // 수면 관련
        Preset(
            title: L.Preset.DeepSleep.title.localized,
            description: L.Preset.DeepSleep.description.localized,
            category: .WaterDrop,
            filter: .Cave,
            audioVariation: AudioVariation(volume: 0.6, pitch: -2.0, interval: 1.5),
            color: "B8D4E8"
        ),
        Preset(
            title: L.Preset.QuickSleep.title.localized,
            description: L.Preset.QuickSleep.description.localized,
            category: .SingingBowl,
            filter: .Empty,
            audioVariation: AudioVariation(volume: 0.5, pitch: 0.0, interval: 1.2),
            color: "F5C89B"
        ),

        // 휴식 관련
        Preset(
            title: L.Preset.Meditation.title.localized,
            description: L.Preset.Meditation.description.localized,
            category: .Bird,
            filter: .Forest,
            audioVariation: AudioVariation(volume: 0.5, pitch: -1.0, interval: 1.8),
            color: "9EC49A"
        ),
        Preset(
            title: L.Preset.Rest.title.localized,
            description: L.Preset.Rest.description.localized,
            category: .SingingBowl,
            filter: .SingingBowl,
            audioVariation: AudioVariation(volume: 0.4, pitch: -0.5, interval: 2.0),
            color: "FFD4A3"
        ),

        // 집중 관련
        Preset(
            title: L.Preset.Focus.title.localized,
            description: L.Preset.Focus.description.localized,
            category: .WaterDrop,
            filter: .WaterDrop,
            audioVariation: AudioVariation(volume: 0.7, pitch: 0.5, interval: 0.8),
            color: "D0E3F0"
        ),
        Preset(
            title: L.Preset.Reading.title.localized,
            description: L.Preset.Reading.description.localized,
            category: .Bird,
            filter: .Bird,
            audioVariation: AudioVariation(volume: 0.6, pitch: 0.0, interval: 1.0),
            color: "B5D8A7"
        ),

        // 자연의 소리
        Preset(
            title: L.Preset.ForestDawn.title.localized,
            description: L.Preset.ForestDawn.description.localized,
            category: .Bird,
            filter: .Cuckoo,
            audioVariation: AudioVariation(volume: 0.5, pitch: -0.5, interval: 1.5),
            color: "C8E6C9"
        ),

        // Rain 카테고리
        Preset(
            title: L.Preset.SoftRain.title.localized,
            description: L.Preset.SoftRain.description.localized,
            category: .Rain,
            filter: .SoftRain,
            audioVariation: AudioVariation(volume: 0.7, pitch: 0.0, interval: 1.0),
            color: "A8D4E6"
        ),
        Preset(
            title: L.Preset.CityRain.title.localized,
            description: L.Preset.CityRain.description.localized,
            category: .Rain,
            filter: .CityRain,
            audioVariation: AudioVariation(volume: 0.6, pitch: -0.5, interval: 1.2),
            color: "8BC4D8"
        ),

        // Ambient 카테고리
        Preset(
            title: L.Preset.Underwater.title.localized,
            description: L.Preset.Underwater.description.localized,
            category: .Ambient,
            filter: .Underwater,
            audioVariation: AudioVariation(volume: 0.5, pitch: -1.0, interval: 1.5),
            color: "B8D8E8"
        ),
        Preset(
            title: L.Preset.DeepMeditation.title.localized,
            description: L.Preset.DeepMeditation.description.localized,
            category: .Ambient,
            filter: .MeditationPad,
            audioVariation: AudioVariation(volume: 0.4, pitch: 0.0, interval: 2.0),
            color: "D4C8E8"
        ),
        Preset(
            title: L.Preset.CosmicAtmosphere.title.localized,
            description: L.Preset.CosmicAtmosphere.description.localized,
            category: .Ambient,
            filter: .Atmosphere,
            audioVariation: AudioVariation(volume: 0.5, pitch: -0.5, interval: 1.8),
            color: "C5B8E8"
        ),

        // ASMR 카테고리
        Preset(
            title: L.Preset.TypingFocus.title.localized,
            description: L.Preset.TypingFocus.description.localized,
            category: .ASMR,
            filter: .Keyboard,
            audioVariation: AudioVariation(volume: 0.6, pitch: 0.0, interval: 0.8),
            color: "F5D0E0"
        ),
        Preset(
            title: L.Preset.CameraClick.title.localized,
            description: L.Preset.CameraClick.description.localized,
            category: .ASMR,
            filter: .Camera,
            audioVariation: AudioVariation(volume: 0.5, pitch: 0.5, interval: 1.0),
            color: "E8C8D8"
        ),

        // 확장된 SingingBowl
        Preset(
            title: L.Preset.TibetanMeditation.title.localized,
            description: L.Preset.TibetanMeditation.description.localized,
            category: .SingingBowl,
            filter: .TibetanBowl,
            audioVariation: AudioVariation(volume: 0.5, pitch: 0.0, interval: 1.5),
            color: "FDD0A8"
        ),

        // 확장된 Bird
        Preset(
            title: L.Preset.JungleMorning.title.localized,
            description: L.Preset.JungleMorning.description.localized,
            category: .Bird,
            filter: .Jungle,
            audioVariation: AudioVariation(volume: 0.6, pitch: 0.0, interval: 1.2),
            color: "98D4A0"
        )
    ]
}

extension SoundListView {

    /// 오리지널 사운드 리스트
    static let originalSounds = [
        OriginalSound(name: L.Category.waterdrop.localized, filter: .WaterDrop, category: .WaterDrop),
        OriginalSound(name: L.Category.singingBowl.localized, filter: .SingingBowl, category: .SingingBowl),
        OriginalSound(name: L.Category.bird.localized, filter: .Bird, category: .Bird),
        OriginalSound(name: L.Category.rain.localized, filter: .SoftRain, category: .Rain),
        OriginalSound(name: L.Category.ambient.localized, filter: .AmbientKeys, category: .Ambient),
        OriginalSound(name: L.Category.asmr.localized, filter: .Keyboard, category: .ASMR)
    ]

}
