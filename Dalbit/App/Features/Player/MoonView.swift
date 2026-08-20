//
//  MoonView.swift
//  Dalbit
//
//  홈의 달 — 굴러가는 구면(RollingSphereSurface), 위상 그림자(MoonShadow), 본체(CampfireView).
//

import SwiftUI

struct RollingSphereSurface: View, Animatable {
    var roll: Double            // 가로 회전 각도(도) — 좌우 굴림(소리 전환)
    var rollY: Double           // 세로 회전 각도(도) — 위아래 굴림(모드 전환)
    let isPlaying: Bool
    var showIcon: Bool = true    // 재생/일시정지 심볼 표시
    var showSpots: Bool = true   // 분화구(크레이터) 표시
    var iconColor: Color = .white

    // 두 축을 함께 보간 → 가로/세로 모두 표면 회전이 실제로 굴러간다.
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(roll, rollY) }
        set { roll = newValue.first; rollY = newValue.second }
    }

    private let sphereR: CGFloat = 104
    private var rx: Double { roll * .pi / 180 }
    private var ry: Double { rollY * .pi / 180 }

    // 표면 위 한 점(경도 lon, 기준 y=baseY)의 화면 투영: 위치·압축·가시성
    private func markX(_ lon: Double) -> CGFloat { CGFloat(sin(rx + lon)) * sphereR }
    private func markY(_ baseY: CGFloat) -> CGFloat { baseY * CGFloat(cos(ry)) + CGFloat(sin(ry)) * sphereR }
    private func squashX(_ lon: Double) -> CGFloat { CGFloat(max(0.05, abs(cos(rx + lon)))) }
    private func squashY() -> CGFloat { CGFloat(max(0.05, abs(cos(ry)))) }
    // 앞면(양 축 모두 정면)일 때만 보임
    private func markOpacity(_ lon: Double) -> Double { max(0, cos(rx + lon)) * max(0, cos(ry)) }

    private struct Spot {
        let lon: Double; let y: CGFloat; let size: CGFloat; let light: Bool; let maxOpacity: Double
    }
    // 달 표면: 큰 바다(어두운 마리아) + 작은 크레이터 + 잔잔한 알갱이로 까슬까슬한 질감
    private static let spots: [Spot] = {
        var arr: [Spot] = [
            Spot(lon: 1.5, y: 28,  size: 74, light: false, maxOpacity: 0.28),  // 큰 마리아
            Spot(lon: 4.2, y: 6,   size: 62, light: false, maxOpacity: 0.24),
            Spot(lon: 2.4, y: -36, size: 50, light: false, maxOpacity: 0.20),
            Spot(lon: 0.7, y: -8,  size: 34, light: false, maxOpacity: 0.18),
            Spot(lon: 3.1, y: 48,  size: 38, light: false, maxOpacity: 0.16),
            Spot(lon: 5.3, y: -42, size: 28, light: false, maxOpacity: 0.16),
            Spot(lon: 1.0, y: 54,  size: 20, light: false, maxOpacity: 0.18),
            Spot(lon: 2.0, y: 62,  size: 22, light: true,  maxOpacity: 0.20),  // 밝은 크레이터
            Spot(lon: 4.9, y: 34,  size: 18, light: true,  maxOpacity: 0.18),
            Spot(lon: 3.7, y: -20, size: 16, light: true,  maxOpacity: 0.16)
        ]
        // 까슬한 질감 — 작고 또렷한 알갱이(밝은 돌기 + 어두운 패임)를 표면에 골고루.
        // 같은 구 투영을 쓰므로 굴리면 표면과 함께 굴러간다.
        func frac(_ v: Double) -> Double { v - floor(v) }
        let grainCount = 46
        for i in 0..<grainCount {
            let fi = Double(i)
            let lon = frac(sin(fi * 12.9898) * 43758.5453) * 2 * .pi
            let y = CGFloat(frac(sin(fi * 78.233) * 12543.1234) * 2 - 1) * 92
            let size = CGFloat(3 + frac(sin(fi * 3.71) * 991.7) * 6)        // 3~9 (작은 알갱이)
            let light = frac(sin(fi * 5.13) * 311.1) > 0.5
            let op = 0.10 + frac(sin(fi * 9.17) * 517.3) * 0.16            // 0.10~0.26 (질감 강조)
            arr.append(Spot(lon: lon, y: y, size: size, light: light, maxOpacity: op))
        }
        return arr
    }()

    var body: some View {
        ZStack {
            // 분화구·알갱이 — 50여 개를 "단일 Canvas 한 번"에 그려 굴림 애니메이션을 가볍게.
            // (예전엔 점마다 View라 매 프레임 수십 개 레이아웃 재계산 → 스와이프 끊김)
            if showSpots {
                Canvas { ctx, size in
                    let rxv = rx, ryv = ry
                    let cx = size.width / 2, cy = size.height / 2
                    let cosY = cos(ryv), sinY = sin(ryv)
                    let sqY = CGFloat(max(0.05, abs(cosY)))
                    for s in Self.spots {
                        // 뒷면(가려진 점)은 그리지 않고 건너뜀 — 절반가량 드로우 절감
                        let vis = max(0, cos(rxv + s.lon)) * max(0, cosY)
                        let op = s.maxOpacity * vis
                        if op <= 0.004 { continue }
                        let mx = CGFloat(sin(rxv + s.lon)) * sphereR
                        let my = s.y * CGFloat(cosY) + CGFloat(sinY) * sphereR
                        let sqX = CGFloat(max(0.05, abs(cos(rxv + s.lon))))
                        let r = s.size * 0.78
                        let col: Color = s.light ? .white : Color(white: 0.28)
                        // GraphicsContext는 값 타입 → 복사본에 변형을 적용(원본 불변)
                        var c = ctx
                        c.translateBy(x: cx + mx, y: cy + my)
                        c.scaleBy(x: sqX, y: sqY)   // 가장자리로 갈수록 납작(구의 원근)
                        c.fill(
                            Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                            with: .radialGradient(
                                Gradient(colors: [col.opacity(op), col.opacity(0)]),
                                center: .zero, startRadius: 0, endRadius: r
                            )
                        )
                    }
                }
            }
            // 표면 위 재생/일시정지 심볼 — 표면과 함께 굴러간다 (1개뿐이라 View 유지)
            if showIcon {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(iconColor)
                    .scaleEffect(x: squashX(0), y: squashY(), anchor: .center)
                    .offset(x: markX(0) + (isPlaying ? 0 : 5), y: markY(0))
                    .opacity(markOpacity(0))
            }
        }
    }
}

// MARK: - Moon Phase Shadow

/// 달 위상 그림자: phase 1 = 보름달(그림자 없음), 0 = 반달, -1 = 신월(전부 그림자).
/// 오른쪽에서 그림자가 차오르며 보름→반달→초승달로 변한다. Animatable로 부드럽게 보간.
struct MoonShadow: Shape, Animatable {
    var phase: Double
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        let cx = rect.midX, cy = rect.midY
        let k = CGFloat(max(-1, min(1, phase)))
        let steps = 96
        var pts: [CGPoint] = []
        // 명암 경계(터미네이터) 타원: 위(y=-r) → 아래(y=+r)
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = -r + 2 * r * t
            let xr = sqrt(max(0, r * r - y * y))
            pts.append(CGPoint(x: cx + k * xr, y: cy + y))
        }
        // 터미네이터 오른쪽을 원 밖까지 가득 채움 → 바깥의 clipShape(Circle)이 림에 정확히 맞춰 자른다
        // (외곽을 원호로 근사하지 않으므로 달이 삐져나오지 않음)
        pts.append(CGPoint(x: rect.maxX + r, y: rect.maxY + r))
        pts.append(CGPoint(x: rect.maxX + r, y: rect.minY - r))
        p.addLines(pts)
        p.closeSubpath()
        return p
    }
}

/// 홈의 메인 오브 — "달". 재생을 시작하면 그림자가 차올라 보름달→반달→초승달로 변한다.
struct CampfireView: View {
    let isPlaying: Bool
    var tint: Color = DS.Colors.accent
    var roll: Double = 0    // 가로 회전(좌우 굴림)
    var rollY: Double = 0   // 세로 회전(위아래 굴림)
    var satelliteVisible: Bool = false   // 달을 돌리면 위성이 나와서 궤도를 돈다
    var satelliteStart: Double = 0       // 위성 등장 시각(궤도 위상 기준)
    var satelliteStartAngle: Double = 0.62   // 등장 시작각(좌/우 뒤 랜덤)
    var satelliteHue: Double = 0             // 위성 색상(랜덤)
    var satelliteScale: Double = 1.0         // 위성 크기 배리에이션(랜덤)
    /// 내가 흔들리는 정도(-0.5~0.5). 3D 달의 카메라를 조금 옆으로 옮겨
    /// 시점이 실제로 바뀌게 한다 — 평면 이동만으로는 '달이 움직인다'로 읽힌다.
    var sway: CGSize = .zero

    @State private var breathe = false
    @State private var glow = false
    @State private var moonPhase: Double = 1.0   // 1=보름달, 0=반달, -1=신월
    @State private var moonCycleToken = 0        // 위상 2단계 애니메이션 취소용 (일시정지 시)
    @State private var iconShown = true          // 재생/일시정지 심볼은 잠깐 보였다 사라짐
    @State private var iconToken = 0

    private let moonSize: CGFloat = 220

    /// 달을 RealityKit 3D 구체로 그릴지. 끄면 예전 2D 달로 돌아간다.
    /// (수면 앱이라 실기기 배터리·발열을 재보고 판단할 수 있게 되돌릴 길을 남겨 둔다 —
    ///  설정 > 개발자 모드에서 끌 수 있다)
    @AppStorage("use3DMoon") private var use3DMoon = true

    var body: some View {
        ZStack {
            // 달무리(외곽 글로우)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(isPlaying ? 0.30 : 0.14),
                                 Color.white.opacity(isPlaying ? 0.10 : 0.05),
                                 .clear],
                        center: .center, startRadius: 10, endRadius: 220
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(glow ? 1.06 : 0.9)
                .blur(radius: 34)

            // 위성 — 궤도 뒤쪽 반(달 뒤로 지나감). 오른쪽 뒤에 가려진 채 페이드 인 → 천천히 빠져나옴
            if satelliteVisible {
                satelliteView(front: false)
                    .transition(.opacity)
            }

            // 본체 — 소리마다 바뀌는 색(틴트)의 구체
            if use3DMoon { moon3DView } else { moonView }

            // 위성 — 궤도 앞쪽 반(달 앞으로 지나감)
            if satelliteVisible {
                satelliteView(front: true)
                    .transition(.opacity)
            }
        }
        .frame(width: 240, height: 240)
        .onAppear {
            startBreathing()
            if isPlaying { startMoonCycle() } else { moonPhase = 1.0 }
            revealIcon()
        }
        .onChange(of: isPlaying) { _, playing in
            startBreathing()
            revealIcon()   // 재생/일시정지 바뀌면 심볼을 다시 잠깐 보여줌
            if playing {
                startMoonCycle()
            } else {
                // 일시정지 → 예약된 위상 2단계 취소 + 천천히 보름달로 복귀
                moonCycleToken += 1
                withAnimation(.easeInOut(duration: 6)) { moonPhase = 1.0 }
            }
        }
    }

    /// 재생/일시정지 심볼을 잠깐(약 10초) 보여주고 자동으로 사라지게 한다.
    private func revealIcon() {
        iconShown = true
        iconToken += 1
        let token = iconToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if token == iconToken { iconShown = false }
        }
    }

    /// 위성: 기울어진 타원 궤도를 연속으로 돈다. front=true면 앞쪽 반, false면 뒤쪽 반만 그려
    /// 달 뒤로 자연스럽게 사라졌다 앞으로 나타난다. TimelineView로 매 프레임 위치를 다시 계산.
    @ViewBuilder
    private func satelliteView(front: Bool) -> some View {
        // 약 26분에 한 바퀴 도는 아주 느린 공전 (등장 후 천천히 한 바퀴 돌고 사라짐)
        TimelineView(.animation) { context in
            let period = 1560.0     // 한 바퀴 ≈ 26분 (속도 고정, 더 천천히)
            let startAngle = satelliteStartAngle   // 등장 시작각: 달의 좌/우 뒤(랜덤, 가려진 위치)
            let elapsed = max(0, context.date.timeIntervalSinceReferenceDate - satelliteStart)
            let ang = startAngle + (elapsed / period) * 2 * Double.pi
            // 기울어진 궤도: 가로 넓고 세로 얕게. 아래쪽(앞)일수록 앞·크게, 위쪽(뒤)이면 작게
            let frontness = -cos(ang)              // +면 앞(아래), -면 뒤(위)
            let isFrontHalf = frontness > 0
            let rx = 140.0, ry = 78.0
            let x = sin(ang) * rx
            let y = (-cos(ang) * ry) - 4
            let scale = (0.82 + 0.3 * max(0, frontness)) * satelliteScale   // 크기 배리에이션 반영
            // 달 색과 유사한(analogous) 색 — 항상 색이 돌게 채도 하한을 두고 명도에 상한을 둬서
            // 어떤 달 색에서도 흰색/쨍한 톤이 나오지 않는다. (테두리까지 전부 착색)
            let satColor = Color(hue: satelliteHue, saturation: 0.50, brightness: 0.72)
            let satDeep = Color(hue: satelliteHue, saturation: 0.62, brightness: 0.52)
            let satCore = Color(hue: satelliteHue, saturation: 0.35, brightness: 0.82)  // 코어도 색을 머금은 은은한 밝기
            ZStack {
                // 위성 둘레의 은은한 빛무리 (약하게)
                Circle()
                    .fill(satColor.opacity(0.30))
                    .frame(width: 46, height: 46)
                    .blur(radius: 14)
                // 위성 본체 — 작은 달(부드러운 코어 → 색이 도는 외곽)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [satCore, satColor, satDeep],
                            center: UnitPoint(x: 0.38, y: 0.32),
                            startRadius: 1, endRadius: 18
                        )
                    )
                    .frame(width: 26, height: 26)
                    .shadow(color: satColor.opacity(0.4), radius: 5)
                    .blur(radius: 1.1)   // 전체적으로 살짝 흐릿하게
            }
            .scaleEffect(scale)
            .offset(x: x, y: y)
            .opacity((isFrontHalf == front) ? 0.7 : 0)   // 덜 또렷하게
        }
        .allowsHitTesting(false)
    }

    /// 달 본체 (식이 길어 별도 프로퍼티로 분리 — 컴파일러 타입체크 부담 완화)
    private var moonView: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0.95), tint.opacity(0.60)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .frame(width: moonSize, height: moonSize)
            // 불투명 베이스 — 달 뒤로 지나가는 위성이 비쳐 보이지 않게 한다.
            // (배경색과 동일 → 기존 반투명 룩은 그대로 유지하면서 뒤쪽만 가림)
            .background(Circle().fill(DS.Colors.background))
            .overlay(lightTexture)   // 여러 빛 → 불균일 질감
            // 흐릿한 분화구 — 표면을 따라 굴러감
            .overlay(
                RollingSphereSurface(roll: roll, rollY: rollY, isPlaying: isPlaying,
                                     showIcon: false, showSpots: true)
                    .frame(width: moonSize, height: moonSize)
                    .opacity(0.5)
            )
            // 위상 그림자 — 원 밖까지 채워 림에 딱 맞고, 경계(터미네이터)는 블러로 흐리게.
            // 달을 굴리면(roll/rollY) 그림자도 표면과 함께 미끄러져 구체에 붙어 도는 느낌.
            .overlay(
                MoonShadow(phase: moonPhase)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.05, green: 0.06, blue: 0.13),
                                     Color(red: 0.09, green: 0.10, blue: 0.20)],
                            startPoint: .trailing, endPoint: .leading
                        )
                    )
                    .opacity(0.9)
                    .blur(radius: 7)   // 그림자 경계를 부드럽게
                    // 표면 회전에 맞춰 좌우/상하로 따라 굴러감(주기적이라 무한 스와이프해도 안정)
                    .offset(x: CGFloat(sin(roll * .pi / 180)) * 40,
                            y: CGFloat(sin(rollY * .pi / 180)) * 18)
            )
            // 가장자리 음영
            .overlay(
                Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1.5)
                    .blur(radius: 1)
            )
            // 재생/일시정지 심볼 (그림자 위, 위상에 따라 색 대비) — 잠깐 보였다 사라짐
            .overlay(
                RollingSphereSurface(
                    roll: roll, rollY: rollY, isPlaying: isPlaying,
                    showIcon: true, showSpots: false,
                    iconColor: moonPhase > 0 ? Color(red: 0.18, green: 0.16, blue: 0.10) : .white
                )
                .frame(width: moonSize, height: moonSize)
                .opacity(iconShown ? 1 : 0)
                .animation(.easeInOut(duration: 0.9), value: iconShown)
            )
            .clipShape(Circle())
            // 호흡 진폭 ±1.5% — 눈에 띄지 않고 무의식적으로 따라 쉬게 되는 미묘한 크기 변화
            .scaleEffect(breathe ? 1.015 : 0.985)
            .shadow(color: tint.opacity(0.35), radius: 36, x: 0, y: 12)
    }

    /// RealityKit 구체 본체. 위상 그림자는 실제 조명이 만드는 명암 경계가 대신하므로
    /// 따로 그리지 않는다. 재생/일시정지 심볼과 호흡·그림자는 2D와 동일하게 얹는다.
    private var moon3DView: some View {
        Moon3DView(tint: tint, roll: roll, rollY: rollY, isPlaying: isPlaying,
                   sway: sway, size: moonSize)
            .overlay(
                RollingSphereSurface(
                    roll: roll, rollY: rollY, isPlaying: isPlaying,
                    showIcon: true, showSpots: false,
                    iconColor: .white
                )
                .frame(width: moonSize, height: moonSize)
                .opacity(iconShown ? 1 : 0)
                .animation(.easeInOut(duration: 0.9), value: iconShown)
                .allowsHitTesting(false)
            )
            .scaleEffect(breathe ? 1.015 : 0.985)
            .shadow(color: tint.opacity(0.35), radius: 36, x: 0, y: 12)
    }

    /// 여러 곳에서 쏜 빛(밝은 빛 4 + 그늘 3)을 묶은 불균일 질감 레이어
    private var lightTexture: some View {
        ZStack {
            lightBlob(0.30, 0.26, 0.60, 130, true)
            lightBlob(0.72, 0.38, 0.34, 86, true)
            lightBlob(0.44, 0.76, 0.26, 100, true)
            lightBlob(0.18, 0.56, 0.22, 72, true)
            lightBlob(0.78, 0.80, 0.34, 88, false)
            lightBlob(0.55, 0.12, 0.26, 66, false)
            lightBlob(0.40, 0.42, 0.16, 50, false)
        }
    }

    /// 그믐까지 기울었다가 되돌아오는 데 걸리는 시간(초). 한 왕복은 이 값의 두 배다.
    ///
    /// ⚠️ 여기를 늘릴 때는 **눈에 보이는지**를 함께 따질 것. 예전엔 1125초였는데, 그러면
    ///    터미네이터가 분당 3pt 남짓 움직인다. 경계에 blur(7)까지 걸려 있어서 그 정도 변화는
    ///    사람 눈에 그냥 멈춰 있는 것으로 보였다(2분을 봐도 위상이 0.88→0.86).
    ///    "느리고 고요하게"와 "변하지 않는다"는 다르다.
    private static let moonWaneSeconds: Double = 480

    /// 재생 중: 처음 20초는 위상 1.0→0.88 로 빠르게 드리워 재생을 눌렀다는 피드백을 주고,
    /// 이후 그믐까지 일정한 속도로 기울었다가 되돌아온다 (무한 반복).
    private func startMoonCycle() {
        moonCycleToken += 1
        let token = moonCycleToken
        // 1단계: 그림자가 눈에 보이게 스며들기 시작 (전체 범위 1.92의 1/16 = 0.12)
        withAnimation(.easeOut(duration: 20)) { moonPhase = 0.88 }
        // 2단계: 남은 범위를 **일정한 속도로**.
        // ⚠️ easeInOut 을 쓰지 말 것 — 시작과 끝이 거의 정지 상태라, 사람이 실제로 보는
        //    처음 몇 분 동안 아무 일도 일어나지 않는 것처럼 보인다. 여기서는 완만함보다
        //    "변하고 있다"가 전달되는 게 중요하다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            guard token == moonCycleToken, isPlaying else { return }
            withAnimation(.linear(duration: Self.moonWaneSeconds).repeatForever(autoreverses: true)) {
                moonPhase = -0.92   // 그믐달(아주 얇은 달)
            }
        }
    }

    /// 한 지점에서 쏜 빛(또는 그늘) — 여러 개 겹쳐 불균일한 표면 질감을 만든다
    @ViewBuilder
    private func lightBlob(_ x: Double, _ y: Double, _ op: Double, _ r: CGFloat, _ light: Bool) -> some View {
        Circle().fill(
            RadialGradient(
                colors: [(light ? Color.white : Color.black).opacity(op), .clear],
                center: UnitPoint(x: x, y: y), startRadius: 2, endRadius: r
            )
        )
    }

    /// 달의 호흡 — 공명 호흡(resonance breathing) 연구에 맞춘 분당 6회(10초 주기, 0.1Hz).
    /// 5~7회/분에서 심박변이도(HRV)가 최대가 되고 부교감신경이 활성화되어 진정 효과가 가장 크다.
    /// (들숨 5초 + 날숨 5초, easeInOut 대칭) 사용자가 무의식 중에 따라 쉬도록 진폭은 아주 미묘하게.
    private func startBreathing() {
        let duration: Double = 5.0   // 반주기 5초 → 한 호흡 10초 = 분당 6회
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            breathe = true
        }
        withAnimation(.easeInOut(duration: duration * 1.3).repeatForever(autoreverses: true)) {
            glow = true
        }
    }
}

// MARK: - Now Playing Manager (잠금화면 / 제어센터 컨트롤)

/// 잠금화면·제어센터·이어폰 버튼으로 재생/일시정지/다음/이전을 제어하고,
/// 현재 곡 정보를 표시한다. 콜백(onPlay 등)은 화면에서 주입한다.
