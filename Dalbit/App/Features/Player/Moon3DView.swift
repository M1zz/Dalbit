//
//  Moon3DView.swift
//  Dalbit
//
//  홈 화면의 달을 RealityKit 3D 구체로 그린다.
//
//  ⚠️ 이 뷰는 **그림만 그린다.** 탭·좌우 굴리기·길게 누르기 제스처는 원래부터
//  달이 아니라 홈 화면 전체(orbGesture)에 붙어 있어서, 구체를 3D로 바꿔도
//  조작은 하나도 건드릴 필요가 없다. 그래서 여기선 터치를 아예 받지 않는다.
//
//  · 표면 텍스처와 노멀맵은 코드로 생성한다 — 외부 에셋 0바이트.
//  · 위상 그림자는 따로 그리지 않는다. 한쪽에서 들어오는 빛이 만드는 실제 명암 경계가
//    그 역할을 한다(2D 시절의 MoonShadow보다 자연스럽다).
//  · 소리마다 바뀌는 색(orbTint)은 표면을 다시 굽지 않고 **빛 색**으로 입힌다.
//  · 배경은 투명해야 한다. 환경광을 스카이박스로 주면 검은 사각형이 별을 가리므로,
//    엔티티에만 붙는 ImageBasedLight를 쓴다.
//

import SwiftUI
import RealityKit
import Metal
import simd

/// 아주 느린 자전. 손가락으로 굴리는 회전(제스처)과 겹치면 안 되므로
/// 제스처는 부모(rig)에, 자전은 자식(구체)에 걸어 서로 섞이지 않게 한다.
struct MoonAutoSpinComponent: Component {
    var radiansPerSecond: Float
}

struct MoonAutoSpinSystem: System {
    private static let query = EntityQuery(where: .has(MoonAutoSpinComponent.self))
    init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let spin = entity.components[MoonAutoSpinComponent.self] else { continue }
            entity.orientation *= simd_quatf(angle: spin.radiansPerSecond * Float(context.deltaTime),
                                             axis: SIMD3<Float>(0, 1, 0))
        }
    }
}

/// 등록은 씬을 만들기 전에 단 한 번. (.task 에서 하면 make 가 먼저 돌 수 있다)
private enum MoonSceneRegistry {
    static let registerOnce: Void = {
        MoonAutoSpinComponent.registerComponent()
        MoonAutoSpinSystem.registerSystem()
    }()
}

struct Moon3DView: View {

    var tint: Color
    var roll: Double        // 가로 회전(도) — 좌우 굴림
    var rollY: Double       // 세로 회전(도) — 위아래 굴림
    var isPlaying: Bool
    /// 내가 흔들리는 정도(-0.5~0.5). 카메라를 옆으로 조금 옮겨 시점이 실제로 바뀌게 한다.
    var sway: CGSize = .zero
    /// 화면에 보일 지름(pt)
    var size: CGFloat

    /// 표면 텍스처 해상도.
    /// 화면에는 220pt(=660px @3x)로 보이는데, 등장방형 텍스처는 절반만 앞면에 쓰인다.
    /// 768이면 앞면에 384텍셀뿐이라 660px을 못 채워 뿌옇다 → 1536으로 올려 1.16배 오버샘플.
    private static let textureWidth = 1536
    /// 먼저 띄울 저해상도 — 고해상도는 굽는 데 시간이 걸리므로 회색 구가 오래 보이지 않게 한다
    private static let previewWidth = 384
    /// 자전 속도 — 한 바퀴에 약 9분. 눈치채기 어렵되 멈춰 있지 않다는 건 느껴진다.
    private static let autoSpin: Float = 0.0118

    /// 제스처 회전을 받는 부모
    @State private var rig: Entity?
    /// 표면(자전은 여기 걸린다)
    @State private var moon: ModelEntity?
    @State private var sun: DirectionalLight?
    @State private var camera: PerspectiveCamera?
    /// 카메라가 옆으로 움직이는 폭(씬 단위). 크게 주면 멀미가 난다.
    private static let swayRange: Float = 0.16

    var body: some View {
        RealityView { content in
            _ = MoonSceneRegistry.registerOnce
            content.camera = .virtual

            // 구의 반지름 0.5가 뷰의 약 92%를 채우도록 거리를 잡는다
            // (FOV 30°, 2·asin(0.5/d) ≈ 27.5° → d ≈ 2.1)
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 30
            camera.position = SIMD3<Float>(0, 0, 2.1)
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
            light.look(at: .zero,
                       from: SIMD3<Float>(1.0, 0.35, 0.85),
                       relativeTo: nil)
            content.add(light)
            sun = light

            // rig(제스처 회전) → sphere(자전). 두 회전이 서로를 덮어쓰지 않게 부모/자식으로 나눈다.
            let rigEntity = Entity()
            content.add(rigEntity)
            rig = rigEntity

            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.5),
                                     materials: [UnlitMaterial(color: .darkGray)])
            sphere.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblHolder))
            sphere.components.set(MoonAutoSpinComponent(radiansPerSecond: Self.autoSpin))
            rigEntity.addChild(sphere)
            moon = sphere

        } update: { _ in
            // 내가 흔들리면 카메라가 옆으로 움직인다. 달을 계속 바라보므로
            // 화면상 위치는 그대로인데 보이는 각도만 바뀐다 = 진짜 시차.
            if let cam = camera {
                let sx = Float(sway.width) * Self.swayRange
                let sy = Float(sway.height) * Self.swayRange
                cam.look(at: SIMD3<Float>(0, 0, 0),
                         from: SIMD3<Float>(sx, -sy, 2.1),
                         relativeTo: nil)
            }

            // 손가락 따라 굴러가는 회전은 rig 에 건다(자전은 자식이 따로 돈다)
            //
            // ⚠️ 부호 주의. RealityKit 은 +Y 축 오른손 법칙이라 각도가 **양수**일 때
            // 앞면이 +X(화면 오른쪽)로 간다. 2D 시절 RollingSphereSurface 도
            // markX = sin(roll) 이라 roll 이 커지면 오른쪽으로 갔다.
            // 여기에 -roll 을 넣는 바람에 손가락 반대로 굴렀다.
            rig?.orientation =
                simd_quatf(angle: Float(roll * .pi / 180), axis: SIMD3<Float>(0, 1, 0))
                * simd_quatf(angle: Float(rollY * .pi / 180), axis: SIMD3<Float>(1, 0, 0))

            // 소리 색을 빛에 실어 보낸다 — 표면을 다시 굽지 않아도 색이 바뀐다.
            // 단, 틴트를 그대로 쓰면 보라색 램프처럼 쨍해진다. 흰색 쪽으로 끌어당겨
            // '달빛에 색이 살짝 섞인' 정도로만 남긴다.
            sun?.light.color = Self.moonlight(tint)
            sun?.light.intensity = isPlaying ? 3_900 : 3_100
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .task { await applySurface() }
    }

    // MARK: - 표면

    private func applySurface() async {
        // 저해상도를 먼저 입히고(빠르다), 고해상도가 구워지면 바꿔 낀다
        await bake(width: Self.previewWidth)
        await bake(width: Self.textureWidth)
    }

    private func bake(width: Int) async {
        let maps = await Task.detached(priority: .userInitiated) {
            PlanetTextureFactory.moonMaps(width: width)
        }.value
        guard let maps, let moon else { return }
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
        moon.model?.materials = [material]

#if DEBUG
        print("[Moon3D] \(width)×\(width / 2) 표면 생성 \(String(format: "%.2f", maps.duration))초")
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
    /// strength 가 작을수록 흰색에 가깝다(0 = 순백, 1 = 틴트 그대로).
    private static func moonlight(_ tint: Color, strength: CGFloat = 0.30) -> UIColor {
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        UIColor(tint).getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: 1 - (1 - r) * strength,
                       green: 1 - (1 - g) * strength,
                       blue: 1 - (1 - b) * strength,
                       alpha: 1)
    }

    /// 거의 검은 환경(우주). 완전 검정이면 그림자 쪽이 새까맣게 죽어 2D 달보다 딱딱해
    /// 보이므로, 옅은 푸른 채움광을 남겨 터미네이터를 부드럽게 만든다.
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
