//
//  CustomSound.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/10.
//

import Foundation

/**
 사용자가 커스텀한 사운드 정보를 저장하고 불러오기 위한 구조체
 */
struct CustomSound: Identifiable, Codable, Equatable, Playable {

    let id: UUID
    var title: String
    var category: SoundCategory
    var audioVariation: AudioVariation
    var filter: AudioFilter
    var color: String
    var backgroundSound: String? // 배경 사운드 ("파도", "비", "TV 소음") 저장
    var backgroundVolume: Float? // 배경 볼륨 저장
    var soundLayers: [SoundLayer]? // 여러 사운드 레이어 (다중 사운드 재생용)
    var isFavorite: Bool // 즐겨찾기 여부
    var isPreset: Bool // 프리셋 사운드 여부
    var playCount: Int // 재생 횟수 (스마트 추천용)
    var lastPlayed: Date? // 마지막 재생 시간 (스마트 추천용)

    // 레이어 방식인지 확인
    var isLayeredSound: Bool {
        if let layers = soundLayers, !layers.isEmpty {
            return true
        }
        return false
    }

    init(
        title: String = "",
        category: SoundCategory = .none,
        variation: AudioVariation = AudioVariation(),
        filter: AudioFilter = .none,
        color: String = "",
        backgroundSound: String? = nil,
        backgroundVolume: Float? = nil,
        soundLayers: [SoundLayer]? = nil,
        isFavorite: Bool = false,
        isPreset: Bool = false,
        playCount: Int = 0,
        lastPlayed: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.audioVariation = variation
        self.filter = filter
        self.color = (color == "") ? category.defaultColor : color
        self.backgroundSound = backgroundSound
        self.backgroundVolume = backgroundVolume
        self.soundLayers = soundLayers
        self.isFavorite = isFavorite
        self.isPreset = isPreset
        self.playCount = playCount
        self.lastPlayed = lastPlayed
    }

    /// 사운드 레이어 정보
    struct SoundLayer: Codable, Equatable {
        let category: SoundCategory
        let filter: AudioFilter
        let audioVariation: AudioVariation

        init(category: SoundCategory, filter: AudioFilter, audioVariation: AudioVariation = AudioVariation()) {
            self.category = category
            self.filter = filter
            self.audioVariation = audioVariation
        }
    }
    
    static func == (lhs: CustomSound, rhs: CustomSound) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 오디오 필터 관리를 위한 열거형
enum AudioFilter: String, Codable {
    case none
    // WaterDrop
    case WaterDrop, Basement, Cave, Pipe, Sink
    // SingingBowl
    case SingingBowl, Focus, Training, Empty, Vibration
    case TibetanBowl, Bell, BowlDeep, BowlLoud
    // Bird
    case Bird, Owl, Woodpecker, Forest, Cuckoo
    case Jungle, ForestBird, SpringForest
    // Rain
    case SoftRain, CityRain, RainMaker
    // Ambient
    case AmbientKeys, Underwater, MeditationPad, Atmosphere, IndigoMusic
    // ASMR
    case Keyboard, Camera

    var displayName: String {
        switch self {
        case .none:
            return L.Category.none.localized
        // WaterDrop
        case .WaterDrop:
            return L.Filter.waterdrop.localized
        case .Basement:
            return L.Filter.basement.localized
        case .Cave:
            return L.Filter.cave.localized
        case .Pipe:
            return L.Filter.pipe.localized
        case .Sink:
            return L.Filter.sink.localized
        // SingingBowl
        case .SingingBowl:
            return L.Filter.singingBowl.localized
        case .Focus:
            return L.Filter.focus.localized
        case .Training:
            return L.Filter.training.localized
        case .Empty:
            return L.Filter.empty.localized
        case .Vibration:
            return L.Filter.vibration.localized
        case .TibetanBowl:
            return L.Filter.tibetanBowl.localized
        case .Bell:
            return L.Filter.bell.localized
        case .BowlDeep:
            return L.Filter.bowlDeep.localized
        case .BowlLoud:
            return L.Filter.bowlLoud.localized
        // Bird
        case .Bird:
            return L.Filter.bird.localized
        case .Owl:
            return L.Filter.owl.localized
        case .Woodpecker:
            return L.Filter.woodpecker.localized
        case .Forest:
            return L.Filter.forest.localized
        case .Cuckoo:
            return L.Filter.cuckoo.localized
        case .Jungle:
            return L.Filter.jungle.localized
        case .ForestBird:
            return L.Filter.forestBird.localized
        case .SpringForest:
            return L.Filter.springForest.localized
        // Rain
        case .SoftRain:
            return L.Filter.softRain.localized
        case .CityRain:
            return L.Filter.cityRain.localized
        case .RainMaker:
            return L.Filter.rainMaker.localized
        // Ambient
        case .AmbientKeys:
            return L.Filter.ambientKeys.localized
        case .Underwater:
            return L.Filter.underwater.localized
        case .MeditationPad:
            return L.Filter.meditationPad.localized
        case .Atmosphere:
            return L.Filter.atmosphere.localized
        case .IndigoMusic:
            return L.Filter.indigoMusic.localized
        // ASMR
        case .Keyboard:
            return L.Filter.keyboard.localized
        case .Camera:
            return L.Filter.camera.localized
        }
    }

    var duration: TimeInterval {
        switch self {
        case .none:
            return 0.0

        // WaterDrop
        case .WaterDrop:
            return 1.0
        case .Basement:
            return 2.0
        case .Cave:
            return 2.0
        case .Pipe:
            return 3.0
        case .Sink:
            return 2.0

        // SingingBowl
        case .SingingBowl:
            return 5.0
        case .Focus:
            return 5.0
        case .Training:
            return 4.0
        case .Empty:
            return 5.0
        case .Vibration:
            return 7.0
        case .TibetanBowl:
            return 6.0
        case .Bell:
            return 5.0
        case .BowlDeep:
            return 4.0
        case .BowlLoud:
            return 7.0

        // Bird
        case .Bird:
            return 1.0
        case .Owl:
            return 3.0
        case .Woodpecker:
            return 4.0
        case .Forest:
            return 4.0
        case .Cuckoo:
            return 3.0
        case .Jungle:
            return 8.0
        case .ForestBird:
            return 10.0
        case .SpringForest:
            return 5.0

        // Rain
        case .SoftRain:
            return 10.0
        case .CityRain:
            return 15.0
        case .RainMaker:
            return 4.0

        // Ambient
        case .AmbientKeys:
            return 8.0
        case .Underwater:
            return 3.0
        case .MeditationPad:
            return 12.0
        case .Atmosphere:
            return 6.0
        case .IndigoMusic:
            return 10.0

        // ASMR
        case .Keyboard:
            return 8.0
        case .Camera:
            return 3.0
        }
    }
}

/// 원본 사운드 유형 관리를 위한 열거형
enum SoundCategory: String, Codable, CaseIterable {
    case none
    case WaterDrop, SingingBowl, Bird
    case Rain, Ambient, ASMR

    var displayName: String {
        switch self {
        case .none:
            return L.Category.none.localized
        case .WaterDrop:
            return L.Category.waterdrop.localized
        case .SingingBowl:
            return L.Category.singingBowl.localized
        case .Bird:
            return L.Category.bird.localized
        case .Rain:
            return L.Category.rain.localized
        case .Ambient:
            return L.Category.ambient.localized
        case .ASMR:
            return L.Category.asmr.localized
        }
    }

    var fileName: String {
        switch self {
        case .none:
            return "none"
        case .WaterDrop:
            return "WaterDrop"
        case .SingingBowl:
            return "SingingBowl"
        case .Bird:
            return "Bird"
        case .Rain:
            return "Rain"
        case .Ambient:
            return "Ambient"
        case .ASMR:
            return "ASMR"
        }
    }

    var imageName: String {
        switch self {
        case .none:
            return "none"
        case .WaterDrop:
            return "WaterDrop"
        case .SingingBowl:
            return "SingingBowl"
        case .Bird:
            return "Bird"
        case .Rain:
            return "Rain"
        case .Ambient:
            return "Ambient"
        case .ASMR:
            return "ASMR"
        }
    }

    var defaultColor: String {
        switch self {
        case .none:
            return "CCCCCC"
        case .WaterDrop:
            return "DCE8F5"
        case .SingingBowl:
            return "FDD0A8"
        case .Bird:
            return "ACD6A6"
        case .Rain:
            return "A8D4E6"
        case .Ambient:
            return "C5B8E8"
        case .ASMR:
            return "F5D0E0"
        }
    }

    var iconName: String {
        switch self {
        case .none:
            return "questionmark.circle"
        case .WaterDrop:
            return "drop.fill"
        case .SingingBowl:
            return "circle.circle"
        case .Bird:
            return "bird.fill"
        case .Rain:
            return "cloud.rain.fill"
        case .Ambient:
            return "waveform.path"
        case .ASMR:
            return "hand.tap.fill"
        }
    }
}

import SwiftUI

extension SoundCategory {
    var isFreeCategory: Bool {
        switch self {
        case .WaterDrop, .SingingBowl:
            return true
        default:
            return false
        }
    }

    var themeColor: Color {
        switch self {
        case .none:
            return .gray
        case .WaterDrop:
            return .blue
        case .SingingBowl:
            return .purple
        case .Bird:
            return .green
        case .Rain:
            return .cyan
        case .Ambient:
            return .indigo
        case .ASMR:
            return .pink
        }
    }
}
