//
//  PlanetPrototypeView.swift
//  Dalbit
//
//  태양계 프로토타입 (개발 빌드 전용).
//
//  수·금·지·화·목·토·천·해가 각자 궤도를 돌고, 내 우주선은 태양계 안을 배회한다.
//  우주선의 궤도 반지름이 길게 늘었다 줄었다 하므로 행성들이 가까워졌다 멀어진다.
//
//  궤도 계산은 SolarSystem이 전담한다 — 은하 지도(GalaxyMapView)와 같은 함수를 쓰므로
//  지도에 찍힌 내 위치가 실제로 보이는 풍경과 일치한다.
//
//  텍스처는 PlanetTextureFactory가 코드로 만든다 — 외부 에셋 0바이트.
//

import SwiftUI
import RealityKit
import simd

// MARK: - 컴포넌트 / 시스템

/// 이 엔티티가 어떤 행성인지
struct OrbitComponent: Component {
    var bodyIndex: Int
}

/// 자전 속도
struct PlanetSpinComponent: Component {
    var radiansPerSecond: Float
}

/// 내 우주선(카메라)
struct ShipComponent: Component {}

/// 행성 공전·자전과 우주선 이동을 매 프레임 갱신한다.
/// SwiftUI 상태를 건드리지 않으므로 뷰 갱신이 발생하지 않는다.
struct SolarSystemSystem: System {
    private static let orbits = EntityQuery(where: .has(OrbitComponent.self))
    private static let spins  = EntityQuery(where: .has(PlanetSpinComponent.self))
    private static let ships  = EntityQuery(where: .has(ShipComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        // 지도와 같은 시계를 쓴다
        let t = Date().timeIntervalSinceReferenceDate

        for entity in context.entities(matching: Self.orbits, updatingSystemWhen: .rendering) {
            guard let orbit = entity.components[OrbitComponent.self],
                  let body = SolarBody(rawValue: orbit.bodyIndex) else { continue }
            entity.position = SolarSystem.position(body, at: t)
        }

        for entity in context.entities(matching: Self.spins, updatingSystemWhen: .rendering) {
            guard let spin = entity.components[PlanetSpinComponent.self] else { continue }
            let delta = spin.radiansPerSecond * Float(context.deltaTime)
            entity.orientation *= simd_quatf(angle: delta, axis: SIMD3<Float>(0, 1, 0))
        }

        for entity in context.entities(matching: Self.ships, updatingSystemWhen: .rendering) {
            // 태양(원점) 쪽을 기본으로 보되, 진행 방향을 조금 앞서 봐서 '날아가는' 느낌을 준다
            let me = SolarSystem.shipPosition(at: t)
            let ahead = SolarSystem.shipPosition(at: t + 12)
            let target = ahead * 0.35        // 원점과 진행 방향 사이
            entity.look(at: target, from: me, relativeTo: nil)
        }
    }
}

/// 컴포넌트·시스템 등록은 씬을 만들기 **전에** 끝나 있어야 한다.
/// .task 에서 등록하면 RealityView 의 make 가 먼저 돌 수 있고, 그러면 시스템이
/// 행성을 못 잡아 8개가 전부 원점에 겹쳐 버린다(커다란 행성 하나처럼 보인다).
private enum SolarSceneRegistry {
    static let registerOnce: Void = {
        OrbitComponent.registerComponent()
        PlanetSpinComponent.registerComponent()
        ShipComponent.registerComponent()
        SolarSystemSystem.registerSystem()
    }()
}

// MARK: - 화면

struct PlanetPrototypeView: View {

    @State private var textureWidth: Int = 512
    @State private var spinning = true
    @State private var showStars = true
    @State private var status = "태양계 생성 중…"
    @State private var planets: [Int: ModelEntity] = [:]
    @State private var nearestText = ""

    private let hudTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if showStars { Starfield().ignoresSafeArea() }

            RealityView { content in
                _ = SolarSceneRegistry.registerOnce
                content.camera = .virtual

                // 기본 환경광(IBL)이 밝아서 그냥 두면 구가 고르게 밝고 명암 경계가 사라진다
                if let space = Self.darkEnvironment() {
                    content.environment = .skybox(space)
                }

                let now = Date().timeIntervalSinceReferenceDate

                let camera = PerspectiveCamera()
                camera.camera.fieldOfViewInDegrees = 42
                camera.components.set(ShipComponent())
                camera.look(at: SolarSystem.shipPosition(at: now + 12) * 0.35,
                            from: SolarSystem.shipPosition(at: now),
                            relativeTo: nil)
                content.add(camera)

                // 태양 — 실제로 빛을 내는 점광원 + 눈에 보이는 발광체
                let sunLight = PointLight()
                sunLight.light.intensity = 250_000
                sunLight.light.attenuationRadius = 60
                sunLight.light.color = .init(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
                content.add(sunLight)

                let sunBall = ModelEntity(mesh: .generateSphere(radius: 0.55),
                                          materials: [UnlitMaterial(color: .init(red: 1.0, green: 0.93, blue: 0.76, alpha: 1))])
                content.add(sunBall)

                // 8행성
                for body in SolarBody.allCases {
                    let e = ModelEntity(mesh: .generateSphere(radius: body.bodyRadius),
                                        materials: [UnlitMaterial(color: .darkGray)])
                    e.position = SolarSystem.position(body, at: now)
                    e.components.set(OrbitComponent(bodyIndex: body.rawValue))
                    e.components.set(PlanetSpinComponent(radiansPerSecond: body.spinSpeed))
                    content.add(e)
                    planets[body.rawValue] = e

                    if body.hasRings, let ringTex = PlanetTextureFactory.ringTexture(),
                       let tex = try? TextureResource(image: ringTex, options: .init(semantic: .color)) {
                        var m = PhysicallyBasedMaterial()
                        m.baseColor = .init(texture: .init(tex))
                        m.roughness = 1.0
                        m.metallic = 0.0
                        m.blending = .transparent(opacity: 1.0)
                        m.faceCulling = .none
                        let side = body.bodyRadius * 5.0
                        let ring = ModelEntity(mesh: .generatePlane(width: side, depth: side), materials: [m])
                        ring.orientation = simd_quatf(angle: 0.46, axis: SIMD3<Float>(0, 0, 1))
                        e.addChild(ring)
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                controls
            }
        }
        .navigationTitle("태양계 프로토타입")
        .navigationBarTitleDisplayMode(.inline)
        .task { await rebuild() }
        .onReceive(hudTimer) { _ in
            let n = SolarSystem.nearest(at: Date().timeIntervalSinceReferenceDate)
            nearestText = String(format: "가장 가까운 행성 %@ · %.1f", n.body.koreanName, n.distance)
        }
        .onChange(of: spinning) { _, on in
            for (idx, e) in planets {
                let speed = SolarBody(rawValue: idx)?.spinSpeed ?? 0
                e.components.set(PlanetSpinComponent(radiansPerSecond: on ? speed : 0))
            }
        }
    }

    /// 거의 검은 환경(우주). 아주 약한 푸른 기가 있어 그림자 쪽이 완전히 죽지는 않는다.
    private static func darkEnvironment() -> EnvironmentResource? {
        let w = 16, h = 8
        var px = [UInt8](repeating: 0, count: w * h * 4)
        for i in 0..<(w * h) {
            px[i * 4 + 0] = 3; px[i * 4 + 1] = 3; px[i * 4 + 2] = 7; px[i * 4 + 3] = 255
        }
        var data = px
        let cg: CGImage? = data.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }
            return ctx.makeImage()
        }
        guard let cg else { return nil }
        return try? EnvironmentResource(equirectangular: cg)
    }

    // MARK: - 텍스처

    private func rebuild() async {
        let width = textureWidth
        status = "표면 생성 중… (\(width)×\(width / 2) × 8행성)"
        let began = Date()

        // 8장을 동시에 굽는다 — 코어를 놀리지 않는다
        let maps: [Int: PlanetTextureFactory.Maps] = await withTaskGroup(
            of: (Int, PlanetTextureFactory.Maps?).self
        ) { group in
            for body in SolarBody.allCases {
                group.addTask(priority: .userInitiated) {
                    (body.rawValue, PlanetTextureFactory.make(width: width, body: body))
                }
            }
            var out: [Int: PlanetTextureFactory.Maps] = [:]
            for await (idx, m) in group { if let m { out[idx] = m } }
            return out
        }

        for (idx, m) in maps {
            guard let entity = planets[idx] else { continue }
            do {
                let colorTex = try await TextureResource(image: m.color, options: .init(semantic: .color))
                let normalTex = try await TextureResource(image: m.normal, options: .init(semantic: .normal))
                var material = PhysicallyBasedMaterial()
                material.baseColor = .init(texture: .init(colorTex))
                material.normal = .init(texture: .init(normalTex))
                material.roughness = 0.92
                material.metallic = 0.0
                entity.model?.materials = [material]
            } catch {
                status = "텍스처 업로드 실패: \(error.localizedDescription)"
                return
            }
        }

        let mb = Double(width * (width / 2) * 4 * 2 * SolarBody.allCases.count) / 1_048_576
        status = String(format: "%d×%d × 8행성 · 생성 %.2f초 · 텍스처 약 %.1fMB",
                        width, width / 2, Date().timeIntervalSince(began), mb)
    }

    // MARK: - 조작부

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(status)
                .font(.caption.monospacedDigit())
                .foregroundColor(.white.opacity(0.75))
            Text(nearestText)
                .font(.caption.monospacedDigit())
                .foregroundColor(.white.opacity(0.55))

            HStack(spacing: 10) {
                ForEach([256, 512, 1024], id: \.self) { w in
                    Button("\(w)") {
                        textureWidth = w
                        Task { await rebuild() }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(textureWidth == w
                                               ? Color.white.opacity(0.22)
                                               : Color.white.opacity(0.08)))
                    .foregroundColor(.white)
                }
            }

            Toggle("자전", isOn: $spinning)
                .font(.caption).foregroundColor(.white.opacity(0.75))
            Toggle("별 배경", isOn: $showStars)
                .font(.caption).foregroundColor(.white.opacity(0.75))
        }
        .tint(.white)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(20)
    }
}

#Preview {
    NavigationStack { PlanetPrototypeView() }
        .preferredColorScheme(.dark)
}
