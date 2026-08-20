//
//  MoonJourney.swift
//  Dalbit
//
//  천체가 저 멀리 정면에서 다가와, 눈앞을 지나, 옆으로 밀려나며 멀어지는 여행 궤적.
//
//  ⚠️ 방향이 중요하다. "천체가 나를 향해 날아왔다가 되돌아간다"가 아니라
//     **내가 앞으로 나아가고 있다**로 읽혀야 한다. 그래서 궤적은 좌우 대칭이 아니다.
//
//     · 다가올 때 — 정면 저 멀리. 점 하나가 어둠에서 떠올라 천천히 커진다.
//       옆으로 흐르지 않는다. 내가 그쪽으로 나아가고 있으니까.
//     · 지나칠 때 — 눈앞(정중앙). 여기서만 달이 화면 한가운데 제 크기로 선다.
//     · 지나친 뒤 — 옆으로 빠르게 밀려나며 작아진다. 내가 두고 온 것이다.
//
//  슬롯 두 개가 반 주기씩 어긋난 채 같은 궤적을 돈다. 하나가 옆으로 빠질 때
//  다른 하나가 저 멀리 정면에서 떠오른다 — 앞으로 나아가는 흐름이 끊기지 않는다.
//
//  3D 씬(Moon3DView)과 SwiftUI 오버레이(재생 심볼)가 같은 함수를 쓴다.
//  그래야 심볼이 "지금 눈앞에 있는 천체" 위에만 뜬다.
//

import Foundation
import simd

enum MoonJourney {

    /// 저 멀리서 떠올라 눈앞을 지나 시야 밖으로 밀려나기까지. 수면 앱이라 아주 느리게.
    static let period: Double = 120
    /// 지나친 뒤 옆으로 밀려나는 폭(씬 단위)
    static let travelX: Float = 2.0
    /// 가장 멀 때의 깊이. 이만큼 앞에 있으면 점처럼 보인다.
    static let farZ: Float = 30
    /// 깊이 곡선의 가파르기. 3 이면 눈앞 구간은 완만하고(달이 제 크기로 한참 머문다)
    /// 양 끝에서 급격히 멀어진다(저 멀리 점 하나가 된다).
    ///
    /// ⚠️ 1(선형)로 두면 달이 큰 시간이 2분에 20초도 안 된다. 홈의 주인공이 달인데
    ///    대부분의 시간을 손톱만 하게 보내면 화면이 텅 빈 것처럼 읽힌다.
    private static let depthCurve: Float = 3
    /// 위아래로 스치는 폭 — 매번 같은 높이로 지나가면 기계 같다
    static let travelY: Float = 0.5
    /// 카메라와 천체(z=0)의 거리. 원근 축소율 계산에 쓰므로 씬과 같은 값을 공유한다.
    static let cameraDistance: Float = 4.41

    // MARK: - 여행의 시작점
    //
    // 절대 시각을 그대로 쓰면 화면을 열 때마다 천체가 아무 데나 가 있다. 운이 나쁘면
    // 눈앞이 텅 빈 채로 시작한다 — **만질 것이 없다**는 뜻이다. 홈의 달은 재생·전환·
    // 즐겨찾기가 전부 걸려 있는 조작 대상이라, 열었을 때 눈앞에 없으면 안 된다.
    //
    // 그래서 여행에는 기준점(origin)이 있고, 화면이 오래 그려지지 않다가 다시 그려지는
    // 순간(콜드 런치 / 백그라운드 복귀) 처음부터 다시 시작한다. 그 순간 사람은 화면을
    // 보고 있지 않았으니 위치가 바뀌어도 튀어 보이지 않는다.

    /// 여행이 시작된 시각
    nonisolated(unsafe) private static var origin: Double = 0
    /// 마지막으로 화면이 그려진 시각. 이 간격이 벌어졌다면 그동안 아무도 안 보고 있었다.
    nonisolated(unsafe) private static var lastTick: Double = 0
    /// 이만큼 안 그려졌으면 "다시 열었다"로 본다
    private static let staleGap: Double = 20

    /// 매 프레임 씬이 불러 준다. 필요하면 여행을 처음(달이 눈앞)으로 되돌린다.
    static func tick(at t: Double) {
        if t - lastTick > staleGap { origin = t }
        lastTick = t
    }

    /// 열자마자 달이 멀어져 버리면 만질 틈이 없다. 처음 얼마간은 눈앞에 머물고,
    /// 그 뒤 정지 상태에서 부드럽게 출발한다(속도가 갑자기 붙지 않게).
    private static let holdSeconds: Double = 9
    private static let easeSeconds: Double = 12

    /// 여행 시계. 실제 시간이 아니라 "머물다 천천히 출발하는" 시간이다.
    private static func journeyTime(at t: Double) -> Double {
        let d = max(0, t - origin - holdSeconds)
        return d * d / (d + easeSeconds)     // d→0 에서 속도 0, 멀리서는 (d - ease) 로 수렴
    }

    /// 시작 위상. 슬롯 0 이 0(=눈앞, 정중앙)에서 출발하도록 반 바퀴 밀어 둔다.
    /// 첫 화면은 달이 눈앞에 떠 있는 상태로 시작하고, 곧 옆으로 밀려나며 작아진다.
    /// 같은 순간 슬롯 1 은 저 멀리 정면(-1)에서 떠오르기 시작한다.
    private static let startPhase: Double = 0.5

    /// 슬롯(0/1)의 진행도. -1(저 멀리 정면) → 0(눈앞) → +1(옆으로 빠져 멀어짐)
    static func progress(slot: Int, at t: Double) -> Float {
        return Float(phase(slot: slot, at: t) * 2 - 1)
    }

    /// 0~1 위상. 여행 시계 기준이라 값이 작게 유지된다(아래 bodyIndex 주의사항 참고).
    private static func phase(slot: Int, at t: Double) -> Double {
        let turns = turnsElapsed(slot: slot, at: t)
        return turns - floor(turns)
    }

    private static func turnsElapsed(slot: Int, at t: Double) -> Double {
        journeyTime(at: t) / period + startPhase + Double(slot) * 0.5
    }

    /// 슬롯의 현재 위치
    static func position(slot: Int, at t: Double) -> SIMD3<Float> {
        let u = progress(slot: slot, at: t)
        let side: Float = slot == 0 ? -1 : 1     // 지나간 천체가 빠지는 쪽(좌/우 번갈아)

        // 옆으로 밀려나는 양. 다가오는 동안(u<0)은 거의 0 — 정면에서 커지기만 한다.
        // 지나친 뒤(u>0)에만 급격히 벌어진다. 이 비대칭이 "내가 앞으로 갔다"를 만든다.
        let lateral: Float = u <= 0
            ? -side * travelX * 0.10 * (u * u * u * u)   // 아주 미세하게만 어긋나 있음
            : side * travelX * (1 + u * 1.6) * pow(u, 1.5)

        // 깊이: 양 끝이 가장 멀고 눈앞(u=0)이 가장 가깝다
        let z = -farZ * pow(abs(u), depthCurve)
        // 높이도 지나친 뒤에 더 크게 어긋난다(슬롯마다 반대쪽)
        let ySide: Float = slot == 0 ? 1 : -1
        let y = u <= 0
            ? ySide * travelY * 0.25 * (u * u)
            : -ySide * travelY * pow(u, 1.4)

        return SIMD3<Float>(lateral, y, z)
    }

    /// 양 끝(저 멀리)에서의 페이드. 궤적이 좌우 대칭이 아니라서 u:+1 과 u:-1 의
    /// 위치가 서로 다르다 — 그대로 이으면 시야 끝에 있던 점이 정면으로 순간이동한다.
    /// 어둠 속에서 떠오르고 어둠 속으로 잠기게 해서 그 이음매를 없앤다.
    static func opacity(slot: Int, at t: Double) -> Float {
        let u = progress(slot: slot, at: t)
        let fadeIn = smooth((u + 1) / 0.14)        // -1 → -0.86 사이에서 떠오름
        let fadeOut = smooth((1 - u) / 0.28)       // +0.72 → +1 사이에서 잠김
        return min(fadeIn, fadeOut)
    }

    private static func smooth(_ x: Float) -> Float {
        let k = max(0, min(1, x))
        return k * k * (3 - 2 * k)
    }

    /// 서로 다른 얼굴을 몇 개 돌려 쓸지
    static let faceCount = 12

    /// 이 슬롯이 지금 몇 번째 얼굴인지 — 지나갈 때마다 다른 천체여야 한다.
    ///
    /// ⚠️ 반드시 작은 값으로 순환시킬 것. 큰 값이 그대로 노이즈 좌표(seed)로 들어가면
    /// Int32 변환에서 트랩이 난다. (시작 시각 기준이라 값 자체도 작게 유지된다)
    static func bodyIndex(slot: Int, at t: Double) -> Int {
        let turns = Int(floor(turnsElapsed(slot: slot, at: t)))
        let raw = turns * 2 + slot
        return ((raw % faceCount) + faceCount) % faceCount
    }

    /// 지금 눈앞에 천체가 제대로 와 있는지(0~1).
    /// 재생 심볼은 이 값이 높을 때만 보여야 허공에 뜨지 않는다.
    /// 궤적이 비대칭이라 진행도만으로는 알 수 없어서, 실제 위치를 원근으로 투영해 판단한다.
    static func centrality(at t: Double) -> Double {
        var best: Double = 0
        for slot in 0..<2 {
            let p = position(slot: slot, at: t)
            let shrink = cameraDistance / max(0.5, cameraDistance - p.z)   // 원근 축소율
            let offset = hypot(p.x, p.y) * shrink                          // 화면상 중심 이탈(구 지름 기준)
            let near = Double(smooth((shrink - 0.6) / 0.4))                // 충분히 가까운가
            let centered = Double(max(0, 1 - offset / 0.42))
            best = max(best, near * centered * Double(opacity(slot: slot, at: t)))
        }
        return best
    }
}
