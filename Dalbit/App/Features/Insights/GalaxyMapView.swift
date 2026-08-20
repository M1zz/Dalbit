//
//  GalaxyMapView.swift
//  Dalbit
//
//  은하 지도 (개발 빌드 전용).
//
//  · 태양계: 8행성의 궤도와 현재 위치, 그리고 내 우주선의 위치와 지나온 항로.
//  · 은하계: 나선 은하 안에서 우리 태양계가 어디쯤인지.
//
//  좌표는 전부 SolarSystem에서 가져온다. 3D 씬과 같은 함수를 쓰므로
//  지도에 찍힌 내 위치가 실제로 창밖에 보이는 풍경과 일치한다.
//

import SwiftUI

struct GalaxyMapView: View {

    private enum Scope: String, CaseIterable {
        case solar = "태양계"
        case galaxy = "은하계"
    }

    @State private var scope: Scope = .solar

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.periodic(from: .now, by: 1.0 / 20)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    switch scope {
                    case .solar:  drawSolarSystem(ctx: &ctx, size: size, t: t)
                    case .galaxy: drawGalaxy(ctx: &ctx, size: size, t: t)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack {
                Picker("", selection: $scope) {
                    ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
                legend
            }
        }
        .navigationTitle("은하 지도")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 태양계

    private func drawSolarSystem(ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width / 2, cy = size.height / 2
        // 해왕성 궤도(가장 바깥)가 화면에 들어오도록
        let scale = min(size.width, size.height) * 0.42 / CGFloat(SolarBody.neptune.orbitRadius)
        func P(_ x: Float, _ z: Float) -> CGPoint {
            CGPoint(x: cx + CGFloat(x) * scale, y: cy + CGFloat(z) * scale)
        }

        // 궤도
        for body in SolarBody.allCases {
            let r = CGFloat(body.orbitRadius) * scale
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            ctx.stroke(Path(ellipseIn: rect),
                       with: .color(.white.opacity(0.10)),
                       lineWidth: 0.6)
        }

        // 태양
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)),
                 with: .color(Color(red: 1.0, green: 0.90, blue: 0.62)))
        ctx.draw(ctx.resolve(Text("태양").font(.system(size: 9)).foregroundColor(.white.opacity(0.45))),
                 at: CGPoint(x: cx, y: cy + 14))

        // 내 항로 — 지나온 5분
        var trail = Path()
        var first = true
        for k in stride(from: -300.0, through: 0, by: 3.0) {
            let p = SolarSystem.shipPosition(at: t + k)
            let pt = P(p.x, p.z)
            if first { trail.move(to: pt); first = false } else { trail.addLine(to: pt) }
        }
        ctx.stroke(trail, with: .color(Color(red: 0.66, green: 0.63, blue: 0.98).opacity(0.45)),
                   style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 3]))

        // 행성
        for body in SolarBody.allCases {
            let p = SolarSystem.position(body, at: t)
            let pt = P(p.x, p.z)
            let c = body.palette.high
            let color = Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
            let d = max(4.0, CGFloat(body.bodyRadius) * 26)
            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - d/2, y: pt.y - d/2, width: d, height: d)),
                     with: .color(color))
            ctx.draw(ctx.resolve(Text(body.koreanName)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))),
                     at: CGPoint(x: pt.x, y: pt.y - d/2 - 8))
        }

        // 나
        let me = SolarSystem.shipPosition(at: t)
        let mp = P(me.x, me.z)
        let pulse = 1 + 0.25 * sin(t * 2.2)
        let rr = 9.0 * pulse
        ctx.stroke(Path(ellipseIn: CGRect(x: mp.x - rr, y: mp.y - rr, width: rr*2, height: rr*2)),
                   with: .color(Color(red: 0.72, green: 0.70, blue: 1.0).opacity(0.85)),
                   lineWidth: 1.4)
        ctx.fill(Path(ellipseIn: CGRect(x: mp.x - 3, y: mp.y - 3, width: 6, height: 6)),
                 with: .color(.white))
        ctx.draw(ctx.resolve(Text("나").font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)),
                 at: CGPoint(x: mp.x, y: mp.y + rr + 9))
    }

    // MARK: - 은하계

    private func drawGalaxy(ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width / 2, cy = size.height / 2
        let R = min(size.width, size.height) * 0.46
        func frac(_ v: Double) -> Double { v - floor(v) }

        // 아주 느린 회전 — 은하도 돈다
        let spin = t * 0.004

        // 나선팔 4개
        let arms = 4
        let starCount = 1400
        for i in 0..<starCount {
            let fi = Double(i)
            let arm = i % arms
            let u = frac(sin(fi * 12.9898) * 43758.5453)      // 중심에서의 거리(0~1)
            let rr = pow(u, 0.62)
            // 팔에서 벗어난 정도 — 바깥으로 갈수록 흩어진다
            let spread = (frac(sin(fi * 78.233) * 12543.1234) - 0.5) * (0.35 + rr * 0.75)
            let theta = Double(arm) * (2 * .pi / Double(arms))
                      + rr * 3.4          // 감김
                      + spread
                      + spin
            let r = rr * R
            let x = cx + CGFloat(cos(theta) * r)
            let y = cy + CGFloat(sin(theta) * r * 0.42)       // 살짝 기울어 보이게 눌러 준다
            let sz = 0.7 + frac(sin(fi * 3.71) * 991.7) * 1.5
            // 중심이 밝고 바깥이 어둡다
            let op = (0.10 + 0.55 * (1 - rr)) * (0.5 + frac(sin(fi * 5.13) * 311.1) * 0.5)
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: sz, height: sz)),
                     with: .color(.white.opacity(op)))
        }

        // 중심 팽대부
        for k in stride(from: 0.0, to: 1.0, by: 0.08) {
            let rr = R * 0.16 * CGFloat(1 - k)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - rr, y: cy - rr * 0.5,
                                            width: rr * 2, height: rr)),
                     with: .color(Color(red: 1.0, green: 0.94, blue: 0.78).opacity(0.05)))
        }

        // 우리 태양계 — 오리온 팔 언저리(중심에서 약 60% 지점)에 표시
        let ourR = R * 0.60
        let ourTheta = 0.9 + spin
        let ox = cx + CGFloat(cos(ourTheta)) * ourR
        let oy = cy + CGFloat(sin(ourTheta)) * ourR * 0.42
        let pulse = 1 + 0.3 * sin(t * 1.8)
        let rr = 12.0 * pulse
        ctx.stroke(Path(ellipseIn: CGRect(x: ox - rr, y: oy - rr, width: rr*2, height: rr*2)),
                   with: .color(Color(red: 0.72, green: 0.70, blue: 1.0).opacity(0.9)),
                   lineWidth: 1.4)
        ctx.fill(Path(ellipseIn: CGRect(x: ox - 2.5, y: oy - 2.5, width: 5, height: 5)),
                 with: .color(.white))
        ctx.draw(ctx.resolve(Text("우리 태양계")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)),
                 at: CGPoint(x: ox, y: oy + rr + 10))
    }

    // MARK: - 범례

    private var legend: some View {
        let t = Date().timeIntervalSinceReferenceDate
        let n = SolarSystem.nearest(at: t)
        return VStack(alignment: .leading, spacing: 4) {
            if scope == .solar {
                Text(String(format: "태양에서 %.1f · 가장 가까운 행성 %@",
                            SolarSystem.shipRadius(at: t), n.body.koreanName))
                Text("점선은 지나온 5분간의 항로")
            } else {
                Text("나선팔 4개 · 중심 팽대부")
                Text("우리 태양계는 중심에서 약 60% 지점")
            }
        }
        .font(.caption2.monospacedDigit())
        .foregroundColor(.white.opacity(0.55))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(20)
    }
}

#Preview {
    NavigationStack { GalaxyMapView() }
        .preferredColorScheme(.dark)
}
