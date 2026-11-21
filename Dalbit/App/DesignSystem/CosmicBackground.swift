//
//  CosmicBackground.swift
//  Dalbit
//
//  우주 배경 — 은은하게 유영하는 하늘.
//
//  유영하는 느낌은 세 겹의 깊이에서 나온다. 깊이가 다른 것들이 서로 다른 속도로 움직여야
//  "내가 떠서 흘러간다"로 읽힌다. 한 겹만 있으면 그것이 움직이는 것으로 보인다.
//
//    · 성운   — 가장 멀다. 거의 멈춰 있고 색만 아주 옅게 깔린다.
//    · 먼 별  — 제자리에서 느리게 반짝인다. 움직임을 재는 기준(고정된 하늘)이다.
//    · 가까운 별 — 정면에서 떠올라 천천히 옆으로 흘러간다. 내가 나아가는 방향을 말한다.
//
//  그 위로 아주 드물게 혜성 하나가 지나간다(CosmicEventsView).
//
//  ⚠️ 여기에 "볼거리"를 더하지 말 것. 예전에는 우주선(깜빡이는 빨간 등)과 평면 행성도
//     지나갔는데, 잠들려는 화면에서 깜빡이는 빛은 시선을 끌고, 평면 그림은 3D 천체 옆에서
//     장난감처럼 보였다. 은은함은 덜어낸 데서 나온다.
//

import SwiftUI

/// 아주 드물게 지나가는 혜성 하나.
struct CosmicEventsView: View {

    private struct Comet {
        let from: CGPoint
        let to: CGPoint
        let start: TimeInterval
        let duration: Double
        let scale: CGFloat
        let hue: Double
        var angle: Angle {          // 꼬리가 진행 방향 뒤로 눕게
            .radians(atan2(Double(to.y - from.y), Double(to.x - from.x)))
        }
    }

    @State private var comet: Comet?
    @State private var token = 0
    // 등장 시점이 아니라 발사 시점의 화면 크기를 쓰기 위해 상시 추적
    // (onAppear 때는 레이아웃 확정 전이라 작은 값이 잡혀 경로가 화면 꼭대기에 몰리는 버그가 있었다)
    @State private var canvas: CGSize = .zero
    /// 손쉬운 사용 ▸ 동작 줄이기 — 켜져 있으면 혜성이 지나가지 않는다.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(paused: reduceMotion || comet == nil)) { ctx in
                if let comet {
                    let now = ctx.date.timeIntervalSinceReferenceDate
                    let t = max(0.0, min(1.0, (now - comet.start) / comet.duration))
                    // 양 끝에서 스르륵 나타났다 사라지는 페이드
                    let fade = min(1.0, min(t, 1.0 - t) * 5.0)
                    cometBody(comet)
                        .position(x: comet.from.x + (comet.to.x - comet.from.x) * t,
                                  y: comet.from.y + (comet.to.y - comet.from.y) * t)
                        .opacity(fade)
                }
            }
            .onAppear {
                canvas = geo.size
                scheduleNext()
            }
            .onChange(of: geo.size) { _, size in canvas = size }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 밝은 코어 + 뒤로 길게 흐르는 꼬리 (은은한 톤, 쨍한 흰색 없음)
    private func cometBody(_ comet: Comet) -> some View {
        let tail = Color(hue: comet.hue, saturation: 0.35, brightness: 0.85)
        return ZStack {
            Capsule()
                .fill(LinearGradient(colors: [tail.opacity(0.40), .clear],
                                     startPoint: .trailing, endPoint: .leading))
                .frame(width: 110 * comet.scale, height: 3 * comet.scale)
                .offset(x: -55 * comet.scale)
                .blur(radius: 1.5)
            Circle()
                .fill(Color(hue: comet.hue, saturation: 0.20, brightness: 0.94).opacity(0.8))
                .frame(width: 5 * comet.scale, height: 5 * comet.scale)
                .shadow(color: tail.opacity(0.6), radius: 5)
                .blur(radius: 0.4)
        }
        .rotationEffect(comet.angle)
    }

    // MARK: 스케줄링

    /// 다음 혜성까지 한참 쉰다 — 최소 4분. 드물어야 반갑다. (단일 체인 — token 으로 중복 방지)
    private func scheduleNext(after delay: Double = .random(in: 240...480)) {
        token += 1
        let tk = token
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard tk == token else { return }
            // 동작 줄이기 중이거나 레이아웃이 아직 안 잡혔으면 다음 차례만 잡아 둔다
            guard !reduceMotion, canvas.width >= 100, canvas.height >= 300 else {
                comet = nil
                scheduleNext(after: reduceMotion ? 240 : 3)
                return
            }
            fire(in: canvas)
        }
    }

    /// 위쪽 하늘을 완만한 사선으로 가로지른다 — 달(화면 중앙)을 피한다.
    private func fire(in size: CGSize) {
        let leftToRight = Bool.random()
        let y0 = size.height * CGFloat.random(in: 0.08...0.26)
        let duration = Double.random(in: 10...15)
        comet = Comet(from: CGPoint(x: leftToRight ? -80 : size.width + 80, y: y0),
                      to: CGPoint(x: leftToRight ? size.width + 80 : -80,
                                  y: y0 + CGFloat.random(in: 60...200)),
                      start: Date().timeIntervalSinceReferenceDate,
                      duration: duration,
                      scale: .random(in: 0.8...1.3),
                      hue: Bool.random() ? .random(in: 0.55...0.62)   // 얼음빛 청색
                                         : .random(in: 0.08...0.13))  // 따뜻한 주황
        token += 1
        let tk = token
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            guard tk == token else { return }
            comet = nil
            scheduleNext()
        }
    }
}

/// 성운 · 먼 별 · 가까운 별 — 깊이가 다른 세 겹의 하늘.
struct Starfield: View {
    private static let bleed: CGFloat = 70
    private let farCount = 90
    private let nearCount = 40
    /// 동작 줄이기 — 별이 흐르지도 반짝이지도 않고 제자리에 머문다(한 장의 밤하늘).
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private func frac(_ v: Double) -> Double { v - floor(v) }
    /// 별 번호와 소금값으로 만드는 0~1 난수(매번 같은 자리)
    private func hash(_ i: Int, _ salt: Double) -> Double { frac(sin(Double(i) * salt) * 733.7) }

    /// 앞으로 나아가는 속도. 가까운 별이 중심에서 태어나 바깥으로 흘러가며 커진다 = 내가 다가간다.
    ///
    /// ⚠️ 방향을 뒤집지 말 것. 별이 가장자리에서 중심으로 모이면 **뒤로 물러나는** 느낌이 된다.
    ///    홈의 천체는 정면에서 다가와 옆으로 빠져나가는데(MoonJourney), 별이 반대로 흐르면
    ///    두 레이어가 서로 다른 말을 해서 "앞으로 간다"가 무너진다.
    ///
    /// 느려야 한다. 0.05 였을 때는 별이 20초에 한 번씩 화면 밖으로 쏟아져 워프처럼 보였다.
    /// 천체의 여행(MoonJourney.period)과 같은 비율로 늦춰 둔 값이다.
    private let zSpeed = 0.02

    /// 성운 — (가로 위치, 세로 위치, 색상, 떠도는 주기)
    private let clouds: [(x: Double, y: Double, hue: Double, period: Double)] = [
        (0.18, 0.22, 0.74, 170),    // 보라
        (0.86, 0.58, 0.60, 230),    // 남색
        (0.30, 0.90, 0.52, 200),    // 청록
    ]

    var body: some View {
        // 30fps 면 충분하다 — 이렇게 느린 움직임은 그 이상에서 차이가 보이지 않고, 밤새 켜 두는 화면이다.
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { tl in
            // 멈춘 하늘은 늘 같은 자리여야 한다 — 시각이 아니라 고정된 위상으로 그린다.
            let t = reduceMotion ? 7.0 : tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                drawClouds(&ctx, size: size, t: t)
                drawFarStars(&ctx, size: size, t: t)
                drawNearStars(&ctx, size: size, t: t)
            }
        }
        // 화면보다 넉넉하게 그린다. 홈에서는 내 흔들림을 따라 하늘이 밀리고 기우는데,
        // 화면 크기에 딱 맞추면 그때 성운이 잘린 가장자리가 비스듬한 선으로 드러난다.
        .padding(-Self.bleed)
        .allowsHitTesting(false)
    }

    /// 가장 먼 겹. 색만 옅게 깔리고, 몇 분에 걸쳐 조금 떠돈다.
    private func drawClouds(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let reach = max(size.width, size.height) * 0.62
        for (i, c) in clouds.enumerated() {
            let w = t * 2 * Double.pi / c.period + Double(i) * 2.1
            let center = CGPoint(x: size.width * (c.x + 0.05 * sin(w)),
                                 y: size.height * (c.y + 0.04 * cos(w * 0.8)))
            let color = Color(hue: c.hue, saturation: 0.55, brightness: 0.75)
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - reach, y: center.y - reach,
                                            width: reach * 2, height: reach * 2)),
                     with: .radialGradient(Gradient(colors: [color.opacity(0.11), color.opacity(0.04), .clear]),
                                           center: center, startRadius: 0, endRadius: reach))
        }
    }

    /// 고정된 하늘. 흐르지 않고 제자리에서 아주 느리게 반짝인다.
    private func drawFarStars(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        for i in 0..<farCount {
            let x = hash(i, 2.17) * size.width
            let y = hash(i, 4.51) * size.height
            let sz = 0.6 + hash(i, 3.71) * 1.0
            let twinkle = 0.75 + 0.25 * sin(t * 0.45 + Double(i))   // 한 번 반짝이는 데 14초
            let op = (0.10 + hash(i, 5.13) * 0.30) * twinkle
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: sz, height: sz)),
                     with: .color(.white.opacity(op)))
        }
    }

    /// 정면에서 떠올라 바깥으로 흘러간다. 가까운 별일수록 빠르고 크고 밝다.
    private func drawNearStars(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width / 2, cy = size.height / 2
        let maxR = (size.width * size.width + size.height * size.height).squareRoot() / 2 * 1.05
        for i in 0..<nearCount {
            let k = i + 1000                                    // 먼 별과 다른 난수 줄기
            let near = hash(k, 7.13)                            // 0(멀다) ~ 1(가깝다)
            let ang = hash(k, 2.17) * 2 * Double.pi
            // 위상을 '더하면' 별이 중심 → 바깥으로 흐른다. 즉 내가 앞으로 나아가는 것.
            let rad = frac(hash(k, 4.51) + t * zSpeed * (0.35 + near))
            let radius = rad * rad * maxR                       // 정면(중심)에선 느리고 스쳐 갈수록 빨라짐
            let sz = (0.8 + near * 1.8) * (0.3 + rad * 1.4)     // 다가올수록(가장자리) 커짐
            let born = min(1, rad / 0.2)                        // 중심에서 서서히 나타남
            let gone = 1 - max(0, (rad - 0.8) / 0.2)            // 가장자리에서 사라짐
            let op = (0.14 + near * 0.36) * born * max(0, gone)
            if op > 0.003 {
                ctx.fill(Path(ellipseIn: CGRect(x: cx + cos(ang) * radius, y: cy + sin(ang) * radius,
                                                width: sz, height: sz)),
                         with: .color(.white.opacity(op)))
            }
        }
    }
}

// MARK: - Haptics (가벼운 촉각 피드백 — 휴식 앱답게 은은하게)
