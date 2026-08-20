//
//  Moon3DView.swift
//  Dalbit
//
//  홈 화면의 천체를 RealityKit 3D 구체로 그린다.
//
//  천체는 한자리에 머물지 않는다. 멀리서 다가와 스쳐 지나가고 다시 멀어진다 —
//  내가 우주를 떠가고 있기 때문이다. 궤적은 MoonJourney 가 정한다.
//  슬롯 두 개가 반 주기씩 어긋나 있어서, 하나가 멀어질 때 다른 하나가 다가온다.
//
//  ⚠️ 이 뷰는 그림만 그린다. 탭·좌우 굴리기·길게 누르기는 원래부터 달이 아니라
//  홈 화면 전체(orbGesture)에 붙어 있다.
//

import SwiftUI
import RealityKit
import Metal
import simd

// MARK: - 컴포넌트 / 시스템

/// 여행 슬롯(0/1)
struct MoonJourneyComponent: Component {
    var slot: Int
}

/// 아주 느린 자전
struct MoonAutoSpinComponent: Component {
    var radiansPerSecond: Float
}

/// 천체를 궤적 위로 옮기고, 표면을 천천히 자전시킨다.
struct MoonJourneySystem: System {
    private static let travel = EntityQuery(where: .has(MoonJourneyComponent.self))
    private static let spins  = EntityQuery(where: .has(MoonAutoSpinComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let t = Date().timeIntervalSinceReferenceDate
        for e in context.entities(matching: Self.travel, updatingSystemWhen: .rendering) {
            guard let c = e.components[MoonJourneyComponent.self] else { continue }
            e.position = MoonJourney.position(slot: c.slot, at: t)
        }
        for e in context.entities(matching: Self.spins, updatingSystemWhen: .rendering) {
            guard let s = e.components[MoonAutoSpinComponent.self] else { continue }
            e.orientation *= simd_quatf(angle: s.radiansPerSecond * Float(context.deltaTime),
                                        axis: SIMD3<Float>(0, 1, 0))
        }
    }
}

/// 등록은 씬을 만들기 전에 단 한 번. (.task 에서 하면 make 가 먼저 돌 수 있다)
private enum MoonSceneRegistry {
    static let registerOnce: Void = {
        MoonJourneyComponent.registerComponent()
        MoonAutoSpinComponent.registerComponent()
        MoonJourneySystem.registerSystem()
    }()
}

// MARK: - 화면

struct Moon3DView: View {

    var tint: Color
    var roll: Double        // 가로 회전(도) — 좌우 굴림
    var rollY: Double       // 세로 회전(도) — 위아래 굴림
    var isPlaying: Bool
    /// 내가 흔들리는 정도(-0.5~0.5). 카메라를 옆으로 조금 옮겨 시점이 실제로 바뀌게 한다.
    var sway: CGSize = .zero
    /// 가장 가까울 때 화면에 보일 지름(pt)
    var size: CGFloat

    /// 천체가 옆으로 지나가려면 뷰가 달보다 넓어야 한다.
    /// 프레임과 카메라 거리를 같은 배율로 키우면 화면상 크기는 그대로 유지된다.
    private static let frameScale: CGFloat = 2.1
    private static let baseDistance: Float = 2.1
    /// 표면 텍스처 — 앞면(절반)이 화면 픽셀 수와 얼추 맞는 지점
    private static let textureWidth = 1280
    private static let previewWidth = 384
    private static let autoSpin: Float = 0.0118
    private static let swayRange: Float = 0.16

    @State private var camera: PerspectiveCamera?
    /// 슬롯별 엔티티. rig(궤적) → tilt(제스처 회전) → sphere(자전·표면)
    @State private var tilts: [Int: Entity] = [:]
    @State private var spheres: [Int: ModelEntity] = [:]
    /// 슬롯에 현재 어떤 천체의 얼굴이 입혀져 있는지
    @State private var appliedBody: [Int: Int] = [:]

    private let bodyCheck = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        RealityView { content in
            _ = MoonSceneRegistry.registerOnce
            content.camera = .virtual

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 30
            camera.position = SIMD3<Float>(0, 0, Self.baseDistance * Float(Self.frameScale))
            content.add(camera)
            self.camera = camera

            // 엔티티 전용 환경광 — 배경을 칠하지 않으므로 뒤의 별밭이 그대로 보인다
            let iblHolder = Entity()
            if let env = Self.darkEnvironment() {
                iblHolder.components.set(
                    ImageBasedLightComponent(source: .single(env), intensityExponent: 0)
                )
            }
            content.add(iblHolder)

            // 한쪽에서 들어오는 빛 → 명암 경계(터미네이터)가 위상 그림자 역할을 한다
            let light = DirectionalLight()
            light.light.intensity = 3_900
            light.look(at: .zero, from: SIMD3<Float>(1.0, 0.35, 0.85), relativeTo: nil)
            content.add(light)
            sun = light

            let now = Date().timeIntervalSinceReferenceDate
            for slot in 0..<2 {
                let rig = Entity()
                rig.components.set(MoonJourneyComponent(slot: slot))
                rig.position = MoonJourney.position(slot: slot, at: now)
                content.add(rig)

                let tilt = Entity()
                rig.addChild(tilt)
                tilts[slot] = tilt

                let sphere = ModelEntity(mesh: .generateSphere(radius: 0.5),
                                         materials: [UnlitMaterial(color: .darkGray)])
                sphere.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblHolder))
                sphere.components.set(MoonAutoSpinComponent(radiansPerSecond: Self.autoSpin))
                tilt.addChild(sphere)
                spheres[slot] = sphere
            }

        } update: { _ in
            // 내가 흔들리면 카메라가 옆으로 움직인다. 천체를 계속 바라보므로
            // 화면상 위치는 그대로인데 보이는 각도만 바뀐다 = 진짜 시차.
            if let cam = camera {
                let d = Self.baseDistance * Float(Self.frameScale)
                let sx = Float(sway.width) * Self.swayRange
                let sy = Float(sway.height) * Self.swayRange
                cam.look(at: SIMD3<Float>(0, 0, 0),
                         from: SIMD3<Float>(sx, -sy, d),
                         relativeTo: nil)
            }

            // 손가락 따라 굴러가는 회전. RealityKit 은 +Y 오른손 법칙이라
            // 각도가 양수일 때 앞면이 오른쪽으로 간다(2D 의 markX = sin(roll) 과 같다).
            let q = simd_quatf(angle: Float(roll * .pi / 180), axis: SIMD3<Float>(0, 1, 0))
                  * simd_quatf(angle: Float(rollY * .pi / 180), axis: SIMD3<Float>(1, 0, 0))
            for (_, tilt) in tilts { tilt.orientation = q }

            sun?.light.color = Self.moonlight(tint)
            sun?.light.intensity = isPlaying ? 3_900 : 3_100
        }
        .frame(width: size * Self.frameScale, height: size * Self.frameScale)
        .allowsHitTesting(false)
        .task { await bakeAll(width: Self.previewWidth) ; await bakeAll(width: Self.textureWidth) }
        .onReceive(bodyCheck) { _ in refreshFaces() }
    }

    @State private var sun: DirectionalLight?

    // MARK: - 표면

    /// 두 슬롯 모두 지금 맡은 천체의 얼굴로 굽는다
    private func bakeAll(width: Int) async {
        let now = Date().timeIntervalSinceReferenceDate
        for slot in 0..<2 {
            await bake(slot: slot, body: MoonJourney.bodyIndex(slot: slot, at: now), width: width)
        }
    }

    /// 천체가 한 바퀴 돌아 새 얼굴이 될 때가 되면 다시 굽는다.
    /// 멀리 있을 때(진행도 절댓값이 클 때) 바꿔야 바뀌는 순간이 안 보인다.
    private func refreshFaces() {
        let now = Date().timeIntervalSinceReferenceDate
        for slot in 0..<2 {
            let want = MoonJourney.bodyIndex(slot: slot, at: now)
            guard appliedBody[slot] != want else { continue }
            Task { await bake(slot: slot, body: want, width: Self.textureWidth) }
        }
    }

    private func bake(slot: Int, body: Int, width: Int) async {
        let seed = Float(body) * 97.3
        let warmth = sin(Float(body) * 2.4) * 0.8      // 천체마다 조금씩 다른 색기
        let maps = await Task.detached(priority: .utility) {
            PlanetTextureFactory.moonMaps(width: width, seed: seed, warmth: warmth)
        }.value
        guard let maps, let sphere = spheres[slot] else { return }
        guard
            let colorTex = try? await TextureResource(image: maps.color,
                                                      options: .init(semantic: .color)),
            let normalTex = try? await TextureResource(image: maps.normal,
                                                       options: .init(semantic: .normal))
        else { return }

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(colorTex, sampler: Self.crispSampler))
        material.normal = .init(texture: .init(normalTex, sampler: Self.crispSampler))
        material.roughness = 0.94     // 바위 — 반짝이면 안 된다
        material.metallic = 0.0
        sphere.model?.materials = [material]
        appliedBody[slot] = body

#if DEBUG
        print("[Moon3D] slot \(slot) · 천체 \(body) · \(width)×\(width / 2) · \(String(format: "%.2f", maps.duration))초")
#endif
    }

    /// 구의 가장자리는 텍스처를 비스듬히 훑는다. 이방성 필터링이 없으면
    /// 림 쪽 분화구가 뭉개진다 — 선명도 차이가 가장 크게 나는 지점.
    private static let crispSampler: MaterialParameters.Texture.Sampler = {
        let d = MTLSamplerDescriptor()
        d.minFilter = .linear
        d.magFilter = .linear
        d.mipFilter = .linear
        d.maxAnisotropy = 16
        d.sAddressMode = .repeat      // 경도 방향은 순환
        d.tAddressMode = .clampToEdge
        return .init(d)
    }()

    /// 틴트를 흰색 쪽으로 끌어당긴 '달빛' 색.
    private static func moonlight(_ tint: Color, strength: CGFloat = 0.30) -> UIColor {
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        UIColor(tint).getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: 1 - (1 - r) * strength,
                       green: 1 - (1 - g) * strength,
                       blue: 1 - (1 - b) * strength,
                       alpha: 1)
    }

    /// 거의 검은 환경(우주). 완전 검정이면 그림자 쪽이 새까맣게 죽어 딱딱해 보인다.
    private static func darkEnvironment() -> EnvironmentResource? {
        let w = 16, h = 8
        var px = [UInt8](repeating: 0, count: w * h * 4)
        for i in 0..<(w * h) {
            px[i * 4 + 0] = 20; px[i * 4 + 1] = 20; px[i * 4 + 2] = 34; px[i * 4 + 3] = 255
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
}
