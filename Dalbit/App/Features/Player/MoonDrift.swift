//
//  MoonDrift.swift
//  Dalbit
//
//  홈의 천체는 하나다. 화면 한가운데에서 아주 느리게 떠다닌다.
//
//  ⚠️ 천체를 나에게 다가오게 하지 말 것. 예전에는 천체가 저 멀리 정면에서 떠올라 점점 커지며
//     눈앞을 지나 옆으로 빠져나갔고, 그동안 다음 천체가 또 다가왔다. 정면에서 커지며 다가오는
//     물체는 사람이 본능적으로 "부딪힌다"로 읽는다. 마음을 쉬게 하는 앱에서는 안 된다.
//     게다가 이 천체는 탭 · 굴리기 · 길게 누르기를 받는 조작 대상이라, 화면 가운데를 비우면
//     무엇을 만져야 할지 잃는다. 떠 있는 느낌은 별 · 성운 · 내 흔들림(시차)이 맡는다.
//
//  3D 씬(Moon3DView)이 매 프레임 이 위치를 쓴다.
//

import Foundation
import simd

enum MoonDrift {

    /// 카메라와 천체(원점)의 거리
    static let cameraDistance: Float = 4.41

    /// 떠다니는 폭(씬 단위, 구 반지름 0.5 기준)과 주기(초).
    /// 가로 · 세로 · 깊이의 주기를 서로 다르게 둬서 같은 길을 오가지 않고 천천히 배회한다.
    /// 깊이 폭은 아주 작게 — 크기가 2% 남짓만 바뀐다. 다가온다고 느낄 만큼 커지면 안 된다.
    private static let amplitude = SIMD3<Double>(0.05, 0.04, 0.08)
    private static let period = SIMD3<Double>(113, 89, 157)

    static func position(at t: Double) -> SIMD3<Float> {
        let w = 2 * Double.pi / period
        return SIMD3<Float>(Float(amplitude.x * sin(w.x * t)),
                            Float(amplitude.y * sin(w.y * t + 1.3)),
                            Float(amplitude.z * sin(w.z * t + 0.7)))
    }
}
