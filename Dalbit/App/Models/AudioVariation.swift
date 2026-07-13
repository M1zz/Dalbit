//
//  AudioVariation.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/25.
//

import Foundation

/**
 오디오 변형 관리를 위한 구조체
 */
struct AudioVariation: Codable, Equatable {
    var volume: Float
    var pitch: Float
    var interval: Float
    var intervalVariation: Float // 간격 변동폭 (0.0 ~ 1.0)
    var volumeVariation: Float   // 볼륨 변동폭 (0.0 ~ 1.0)
    var pitchVariation: Float    // 피치 변동폭 (0.0 ~ 1.0)

    init(
        volume: Float = 0.5,
        pitch: Float = 0,
        interval: Float = 1.0,
        intervalVariation: Float = 0.0,
        volumeVariation: Float = 0.0,
        pitchVariation: Float = 0.0
    ) {
        self.volume = volume
        self.pitch = pitch
        self.interval = interval
        self.intervalVariation = intervalVariation
        self.volumeVariation = volumeVariation
        self.pitchVariation = pitchVariation
    }
}
