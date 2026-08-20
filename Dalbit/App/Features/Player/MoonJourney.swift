//
//  MoonJourney.swift
//  Dalbit
//
//  천체가 멀리서 다가와 스쳐 지나가고 다시 멀어지는 여행 궤적.
//
//  "부유한다"를 만드는 건 좌우로 흔들리는 게 아니라 **실제로 지나쳐 가는 것**이다.
//  천체 두 개가 반 주기씩 어긋난 채 같은 궤적을 돌아서, 하나가 멀어질 때 다른 하나가
//  다가온다 — 화면이 비는 순간이 없다.
//
//  3D 씬(Moon3DView)과 SwiftUI 오버레이(재생 심볼)가 같은 함수를 쓴다.
//  그래야 심볼이 "지금 중앙에 있는 천체" 위에만 뜬다.
//

import Foundation
import simd

enum MoonJourney {

    /// 한 천체가 다가와 지나가고 멀어지기까지. 수면 앱이라 아주 느리게.
    static let period: Double = 120
    /// 좌우로 지나가는 폭(씬 단위)
    static let travelX: Float = 2.0
    /// 가장 멀 때의 깊이. 이만큼 물러나면 점처럼 작아진다.
    static let farZ: Float = 13
    /// 위아래로 스치는 폭 — 매번 같은 높이로 지나가면 기계 같다
    static let travelY: Float = 0.55

    /// 슬롯(0/1)의 진행도. -1(멀리 왼쪽) → 0(가장 가까움) → +1(멀리 오른쪽)
    static func progress(slot: Int, at t: Double) -> Float {
        let phase = (t / period + Double(slot) * 0.5).truncatingRemainder(dividingBy: 1)
        return Float(phase * 2 - 1)
    }

    /// 슬롯의 현재 위치
    static func position(slot: Int, at t: Double) -> SIMD3<Float> {
        let u = progress(slot: slot, at: t)
        // 멀수록 옆으로도 더 벌어진다 — 원근이 겹쳐 '스쳐 지나감'이 분명해진다
        let x = u * travelX * (1 + abs(u) * 1.6)
        let z = -farZ * u * u
        let y = sin(Double(u) * .pi) * Double(travelY) * (slot == 0 ? 1 : -1)
        return SIMD3<Float>(x, Float(y), z)
    }

    /// 서로 다른 얼굴을 몇 개 돌려 쓸지
    static let faceCount = 12

    /// 이 슬롯이 지금 몇 번째 얼굴인지 — 지나갈 때마다 다른 천체여야 한다.
    ///
    /// ⚠️ 반드시 작은 값으로 순환시킬 것. 절대 시각(약 8억 초) 기반이라 그대로 쓰면
    /// 6천만이 넘고, 이 값이 노이즈 좌표(seed)로 들어가면 Int32 변환에서 트랩이 난다.
    static func bodyIndex(slot: Int, at t: Double) -> Int {
        let turns = Int(floor(t / period + Double(slot) * 0.5))
        let raw = turns * 2 + slot
        return ((raw % faceCount) + faceCount) % faceCount
    }

    /// 가장 가까운 천체가 얼마나 중앙에 와 있는지(0~1).
    /// 재생 심볼은 이 값이 높을 때만 보여야 허공에 뜨지 않는다.
    static func centrality(at t: Double) -> Double {
        let a = abs(progress(slot: 0, at: t))
        let b = abs(progress(slot: 1, at: t))
        let nearest = min(a, b)                     // 0 = 정중앙
        return Double(max(0, 1 - nearest / 0.45))   // 0.45 를 넘어가면 0
    }
}
