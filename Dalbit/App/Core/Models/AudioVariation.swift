//
//  AudioVariation.swift
//  Dalbit
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

// MARK: - 변동폭 적용

/// 값을 흔들어 주는 계산은 **파라미터를 가진 이 타입이 갖는다.**
/// 예전에는 AudioEngineManager 와 AudioLayerManager 가 같은 식을 각자 들고 있었는데,
/// 그러면 한쪽만 고쳤을 때 단일 재생과 레이어 재생의 소리가 조용히 달라진다.
///
/// ⚠️ **피치는 여기 없다.** 두 재생 경로가 쓰는 단위가 달라서다 —
///    AudioEngineManager 는 세미톤(±24), AudioLayerManager 는 센트(×100)로 다룬다.
///    같아 보인다고 하나로 합치면 한쪽 음정이 100배로 틀어진다.
extension AudioVariation {

    /// 변동폭을 적용한 실제 재생 간격(초). 너무 촘촘해지지 않게 0.1초를 하한으로 둔다.
    var randomizedInterval: Double {
        let base = Double(interval)
        let amount = Double(intervalVariation)
        guard amount > 0 else { return base }
        return max(0.1, base * (1.0 + Double.random(in: -amount...amount)))
    }

    /// 변동폭을 적용한 실제 볼륨. 0으로 떨어져 소리가 사라지지 않게 0.1을 하한으로 둔다.
    var randomizedVolume: Float {
        guard volumeVariation > 0 else { return volume }
        let factor = Float.random(in: -volumeVariation...volumeVariation)
        return max(0.1, min(1.0, volume * (1.0 + factor)))
    }
}
