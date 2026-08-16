//
//  CosmicBackground.swift
//  Dalbit
//
//  우주 배경 — 흐르는 별(Starfield)과 가끔 지나가는 혜성·행성(CosmicEvents).
//  StarryBackground 가 이 둘을 얹어 쓴다.
//

import SwiftUI

struct CosmicEventsView: View {
    private enum Kind { case comet, planet, spaceship }

    private struct Event {
        let kind: Kind
        let from: CGPoint
        let to: CGPoint
        let start: TimeInterval     // 등장 시각
        let duration: Double
        let scale: CGFloat          // 크기 배리에이션
        let hue: Double             // 색 배리에이션
        let hasRing: Bool           // 행성 고리 여부
        var angle: Angle {          // 진행 방향 (혜성 꼬리·우주선 기수 정렬)
            .radians(atan2(Double(to.y - from.y), Double(to.x - from.x)))
        }
    }

    @State private var event: Event?
    @State private var token = 0
    // 등장 시점이 아니라 발사 시점의 화면 크기를 쓰기 위해 상시 추적
    // (onAppear 때는 레이아웃 확정 전이라 작은 값이 잡혀 경로가 화면 꼭대기에 몰리는 버그가 있었다)
    @State private var canvas: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { ctx in
                if let event {
                    let now = ctx.date.timeIntervalSinceReferenceDate
                    let t = max(0.0, min(1.0, (now - event.start) / event.duration))
                    // 양 끝에서 스르륵 나타났다 사라지는 페이드
                    let fade = min(1.0, min(t, 1.0 - t) * 6.0)
                    eventBody(event, elapsed: now - event.start)
                        .position(x: event.from.x + (event.to.x - event.from.x) * t,
                                  y: event.from.y + (event.to.y - event.from.y) * t)
                        .opacity(fade)
                }
            }
            .onAppear {
                canvas = geo.size
                // 정신 사납지 않게 — 최소 4분에 한 번만 지나간다
                scheduleNext(after: .random(in: 240...360))
            }
            .onChange(of: geo.size) { _, size in canvas = size }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: 이벤트 비주얼

    @ViewBuilder
    private func eventBody(_ event: Event, elapsed: Double) -> some View {
        switch event.kind {
        case .comet:
            // 혜성 — 밝은 코어 + 뒤로 길게 흐르는 꼬리 (은은한 톤, 쨍한 흰색 없음)
            let tail = Color(hue: event.hue, saturation: 0.35, brightness: 0.85)
            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [tail.opacity(0.50), .clear],
                                         startPoint: .trailing, endPoint: .leading))
                    .frame(width: 90 * event.scale, height: 3.5 * event.scale)
                    .offset(x: -45 * event.scale)
                    .blur(radius: 1.5)
                Circle()
                    .fill(Color(hue: event.hue, saturation: 0.20, brightness: 0.94).opacity(0.9))
                    .frame(width: 5.5 * event.scale, height: 5.5 * event.scale)
                    .shadow(color: tail.opacity(0.7), radius: 5)
                    .blur(radius: 0.4)
            }
            .rotationEffect(event.angle)

        case .planet:
            // 먼 행성 — 흐릿하게 천천히 떠간다. 절반 확률로 고리(토성풍)
            let base = Color(hue: event.hue, saturation: 0.45, brightness: 0.62)
            let deep = Color(hue: event.hue, saturation: 0.55, brightness: 0.40)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [base, deep],
                                       center: UnitPoint(x: 0.35, y: 0.30),
                                       startRadius: 1, endRadius: 14 * event.scale)
                    )
                    .frame(width: 22 * event.scale, height: 22 * event.scale)
                if event.hasRing {
                    Ellipse()
                        .stroke(base.opacity(0.55), lineWidth: 1.2)
                        .frame(width: 36 * event.scale, height: 10 * event.scale)
                        .rotationEffect(.degrees(-18))
                }
            }
            .opacity(0.7)
            .blur(radius: 0.6)

        case .spaceship:
            // 우주선 — 작은 동체 + 창문 + 깜빡이는 점멸등
            let blinkOn = sin(elapsed * 2 * Double.pi / 0.9) > 0
            ZStack {
                Capsule()
                    .fill(Color(hue: 0.70, saturation: 0.14, brightness: 0.72))
                    .frame(width: 18 * event.scale, height: 6.5 * event.scale)
                HStack(spacing: 2.2 * event.scale) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color(hue: 0.60, saturation: 0.45, brightness: 0.30))
                            .frame(width: 1.9 * event.scale, height: 1.9 * event.scale)
                    }
                }
                Circle()
                    .fill(Color(hue: 0.02, saturation: 0.70, brightness: 0.92))
                    .frame(width: 2.4 * event.scale, height: 2.4 * event.scale)
                    .offset(x: -9 * event.scale, y: -4.5 * event.scale)
                    .opacity(blinkOn ? 0.95 : 0.15)
            }
            .rotationEffect(event.angle)
            .opacity(0.85)
        }
    }

    // MARK: 스케줄링

    /// delay초 뒤에 다음 이벤트를 발생시킨다 (단일 체인 — token으로 중복 방지)
    private func scheduleNext(after delay: Double) {
        token += 1
        let tk = token
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard tk == token else { return }
            // 레이아웃이 아직 안 잡혔으면 잠시 뒤 재시도
            if canvas.width < 100 || canvas.height < 300 {
                scheduleNext(after: 3)
            } else {
                fire(in: canvas)
            }
        }
    }

    /// 랜덤 종류/경로/속도로 이벤트를 하나 띄우고, 끝나면 지운 뒤 다음을 예약한다
    private func fire(in size: CGSize) {
        let kind: Kind = [.comet, .comet, .planet, .spaceship].randomElement()!   // 혜성을 조금 더 자주
        let from: CGPoint
        let to: CGPoint
        let duration: Double
        let scale: CGFloat
        let hue: Double

        // 달(화면 중앙)을 피해 위/아래 띠에서 지나간다
        let topBand = size.height * CGFloat.random(in: 0.08...0.26)
        let bottomBand = size.height * CGFloat.random(in: 0.74...0.90)
        let leftToRight = Bool.random()

        switch kind {
        case .comet:
            // 위쪽 하늘을 대각선으로 빠르게 가로지른다
            let y0 = topBand
            let y1 = y0 + CGFloat.random(in: 60...220)
            from = CGPoint(x: leftToRight ? -70 : size.width + 70, y: y0)
            to = CGPoint(x: leftToRight ? size.width + 70 : -70, y: y1)
            duration = .random(in: 5.5...8.5)
            scale = .random(in: 0.8...1.4)
            hue = Bool.random() ? .random(in: 0.55...0.62)   // 얼음빛 청색
                                : .random(in: 0.08...0.13)   // 따뜻한 주황
        case .planet:
            // 수평으로 아주 천천히 떠간다 (위 또는 아래 띠)
            let y = Bool.random() ? topBand : bottomBand
            from = CGPoint(x: leftToRight ? -50 : size.width + 50, y: y)
            to = CGPoint(x: leftToRight ? size.width + 50 : -50, y: y + CGFloat.random(in: -20...20))
            duration = .random(in: 30...50)
            scale = .random(in: 0.7...1.5)
            hue = .random(in: 0...1)
        case .spaceship:
            // 완만한 사선으로 지나간다
            let y = Bool.random() ? topBand : bottomBand
            from = CGPoint(x: leftToRight ? -40 : size.width + 40, y: y)
            to = CGPoint(x: leftToRight ? size.width + 40 : -40, y: y + CGFloat.random(in: -70...70))
            duration = .random(in: 9...14)
            scale = .random(in: 0.9...1.4)
            hue = 0
        }

        event = Event(kind: kind, from: from, to: to,
                      start: Date().timeIntervalSinceReferenceDate,
                      duration: duration, scale: scale, hue: hue,
                      hasRing: Bool.random())
        token += 1
        let tk = token
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            guard tk == token else { return }
            event = nil
            // 다음 이벤트까지는 한참 쉰다 — 최소 4분, 드물어야 반갑다
            scheduleNext(after: .random(in: 240...480))
        }
    }
}

struct Starfield: View {
    private let count = 64
    private func frac(_ v: Double) -> Double { v - floor(v) }

    // 방향 전환 주기(초). "최소 5분에 한 번 정도"만 바뀌도록.
    private let segmentDur: Double = 300
    // 방향 순환: 위 → 앞 → 아래 → 앞 → … (세로 반전 사이에는 항상 '앞으로'가 끼어 부드럽게 전환)
    private let modes: [Int] = [0, 2, 1, 2]   // 0=위, 1=아래, 2=앞으로
    @State private var segIndex = 0
    @State private var segStart: Double = 0       // 현재 구간 시작 시각
    @State private var phaseYBase: Double = 0     // 구간 시작 시점까지 누적된 세로 위상
    @State private var phaseZBase: Double = 0     // 구간 시작 시점까지 누적된 전방 위상
    @State private var vDir: Double = 1           // 세로 속도(+면 위로 올라가는 느낌, -면 내려감)
    @State private var wForward: Double = 0       // 전방 레이어 가중치(0=세로, 1=앞으로) — 애니메이션으로 전환
    @State private var started = false

    private let vSpeed = 1.0      // 세로 흐름 속도 배율
    private let zSpeed = 0.05     // 전방 흐름 속도

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            // 누적 위상 = 구간 시작까지의 누적 + 이번 구간 경과분 (방향이 바뀌어도 위치는 연속)
            let phaseY = phaseYBase + vDir * vSpeed * (t - segStart)
            let phaseZ = phaseZBase + zSpeed * (t - segStart)
            let wF = wForward
            Canvas { ctx, size in
                let cx = size.width / 2, cy = size.height / 2
                let maxR = (size.width * size.width + size.height * size.height).squareRoot() / 2 * 1.05
                for i in 0..<count {
                    let fi = Double(i)
                    let sz = 0.7 + frac(sin(fi * 3.71) * 991.7) * 2.3
                    let baseOp = 0.12 + frac(sin(fi * 5.13) * 311.1) * 0.5
                    let tw = 0.7 + 0.3 * sin(t * 1.4 + fi)   // 은은한 반짝임

                    // ── 세로 레이어(위/아래) ── 좌우 이동 없음, 깊이감(시차)으로 속도 차이
                    if wF < 0.999 {
                        let bx = frac(sin(fi * 12.9898) * 43758.5453)
                        let by = frac(sin(fi * 78.233) * 12543.1234)
                        let speed = 0.006 + frac(sin(fi * 9.17) * 517.3) * 0.030
                        let y = frac(by + phaseY * speed) * size.height
                        let x = bx * size.width
                        let rect = CGRect(x: x, y: y, width: sz, height: sz)
                        ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(baseOp * tw * (1 - wF))))
                    }

                    // ── 전방 레이어(앞으로 나아감) ── 중심에서 사방으로 퍼지며 커짐(순 좌우 이동 없음, 대칭)
                    if wF > 0.001 {
                        let ang = frac(sin(fi * 2.17) * 733.7) * 2 * Double.pi
                        let fspd = 0.5 + frac(sin(fi * 7.13) * 421.9)   // 0.5~1.5
                        let rad = frac(frac(sin(fi * 4.51) * 611.3) + phaseZ * fspd)
                        let radius = rad * rad * maxR                   // 가속하며 바깥으로
                        let x = cx + cos(ang) * radius
                        let y = cy + sin(ang) * radius
                        let psz = sz * (0.3 + rad * 1.6)                // 가까워질수록(바깥) 커짐
                        let fadeIn = min(1, rad / 0.2)                  // 중심에서 서서히 등장
                        let fadeOut = 1 - max(0, (rad - 0.8) / 0.2)     // 가장자리에서 사라짐
                        let op = baseOp * tw * wF * fadeIn * max(0, fadeOut)
                        if op > 0.003 {
                            let rect = CGRect(x: x, y: y, width: psz, height: psz)
                            ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(op)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if !started {
                started = true
                segStart = Date().timeIntervalSinceReferenceDate
                applyMode(modes[segIndex], animated: false)
            }
        }
        // 약 5분마다 다음 방향으로 전환
        .onReceive(Timer.publish(every: segmentDur, on: .main, in: .common).autoconnect()) { _ in
            let now = Date().timeIntervalSinceReferenceDate
            // 이번 구간 경과분을 base에 접어 넣어 위치 연속성 유지
            phaseYBase += vDir * vSpeed * (now - segStart)
            phaseZBase += zSpeed * (now - segStart)
            segStart = now
            segIndex = (segIndex + 1) % modes.count
            applyMode(modes[segIndex], animated: true)
        }
    }

    /// 방향 적용: 위(0)/아래(1)는 전방 레이어를 숨기고 세로 속도 부호를, 앞으로(2)는 전방 레이어를 띄운다.
    private func applyMode(_ mode: Int, animated: Bool) {
        switch mode {
        case 0: vDir = 1                                 // 위로 올라가는 느낌(별이 아래로 흐름)
        case 1: vDir = -1                                // 아래로 내려가는 느낌(별이 위로 흐름)
        default: break                                   // 앞으로 — vDir 유지(어차피 가려짐)
        }
        let target: Double = (mode == 2) ? 1 : 0
        if animated {
            withAnimation(.easeInOut(duration: 6)) { wForward = target }
        } else {
            wForward = target
        }
    }
}

// MARK: - Haptics (가벼운 촉각 피드백 — 휴식 앱답게 은은하게)
