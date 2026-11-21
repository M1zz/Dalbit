//
//  Moon3DView.swift
//  Dalbit
//
//  홈 화면의 천체를 RealityKit 3D 구체로 그린다.
//
//  천체는 한자리에 머물지 않는다. 저 멀리 정면에서 떠올라 커지고, 눈앞을 지나면
//  옆으로 밀려나며 작아진다 — 내가 그쪽으로 나아가고 있기 때문이다.
//  궤적은 MoonJourney 가 정한다. 슬롯 두 개가 반 주기씩 어긋나 있어서,
//  하나를 지나쳐 보낼 때 다음 천체가 저 멀리서 떠오른다.
//
//  ⚠️ 이 뷰는 그림만 그린다. 탭·좌우 굴리기·길게 누르기는 원래부터 달이 아니라
//  홈 화면 전체(orbGesture)에 붙어 있다.
//

import SwiftUI
import Combine
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

/// 달의 위상 — 해가 비추는 방향. 그림자는 표면에 칠하는 것이 아니라 빛이 만든다.
///
/// 재생하는 동안 해가 천천히 옆으로, 뒤로 돌아가 보름달 → 하현 → 그믐달로 기울었다가
/// 되돌아온다(2D 달의 MoonShadow 와 같은 주기 · 같은 쪽). 멈추면 다시 보름달로 차오른다.
struct MoonSunComponent: Component {
    /// 재생을 시작한 시각. nil 이면 멈춤 — 보름달로 돌아간다.
    var playingSince: Double?
    /// 해의 각도(라디안). 0 = 내 등 뒤(보름달), π/2 = 옆(반달), π 에 가까울수록 그믐.
    var angle: Double = 0
    var velocity: Double = 0

    /// 그믐까지 기울었다가 되돌아오는 데 걸리는 시간(초). 2D 달의 moonWaneSeconds 와 같다.
    static let waneSeconds: Double = 480
    /// 가장 얇을 때의 위상(2D 와 같은 값). -1 이면 완전히 사라진다.
    static let thinnest: Double = -0.92

    /// 재생한 지 `elapsed` 초일 때의 위상(1 = 보름, 0 = 반달, -1 = 신월) — 일정한 속도로 오간다
    static func phase(elapsed: Double) -> Double {
        let u = elapsed / waneSeconds
        let tri = 1 - abs(u.truncatingRemainder(dividingBy: 2) - 1)   // 0 → 1 → 0 …
        return 1 + (thinnest - 1) * tri
    }
}

/// 손가락으로 굴리는 회전(도). SwiftUI 가 목표만 주고, 실제 각도는 매 프레임 스프링으로 따라간다.
///
/// ⚠️ 회전을 SwiftUI 값으로 바로 꽂지 말 것. RealityView 는 `withAnimation` 을 보간하지 않는다 —
///    놓았을 때 제자리로 돌아오는 스프링, 다음 소리로 넘어가는 한 바퀴가 전부 한 프레임에 **툭** 끊겼고,
///    끌 때도 SwiftUI 가 화면을 다시 그릴 때만 각도가 바뀌어 "끼기긱" 걸리듯 움직였다.
struct MoonRollComponent: Component {
    var target: SIMD2<Double>       // (가로, 세로)
    var current: SIMD2<Double>
    var velocity: SIMD2<Double> = .zero
}

/// 천체를 궤적 위로 옮기고, 표면을 천천히 자전시킨다.
struct MoonJourneySystem: System {
    private static let travel = EntityQuery(where: .has(MoonJourneyComponent.self))
    private static let spins  = EntityQuery(where: .has(MoonAutoSpinComponent.self))
    private static let rolls  = EntityQuery(where: .has(MoonRollComponent.self))
    private static let suns   = EntityQuery(where: .has(MoonSunComponent.self))
    /// 해가 움직이는 스프링. 느리게 — 재생을 누르면 몇 초에 걸쳐 그림자가 스며들고,
    /// 멈추면 몇 초에 걸쳐 보름달로 차오른다.
    private static let sunStiffness: Double = 0.9
    /// 스프링의 빠르기. 클수록 손가락에 바짝 붙는다. 16 이면 약 0.06초 뒤처지고
    /// 넘침 없이(임계 감쇠) 멈춘다 — 손을 따라오되 무게가 느껴지는 정도.
    private static let rollStiffness: Double = 16
    /// 크게 굴러갈 때(다음 소리로 넘기는 한 바퀴, 놓아서 제자리로 돌아올 때)의 스프링.
    ///
    /// ⚠️ 손가락 따라가기와 같은 값(16)을 쓰지 말 것. 한 바퀴(360°)를 그 빠르기로 쫓으면
    ///    출발이 확 튀고 0.3초 만에 끝나 "휙" 하고 꺾여 보인다. 6 이면 천천히 굴러가기 시작해
    ///    약 0.8초에 걸쳐 가라앉는다 — 묵직한 구가 굴러가는 속도다.
    private static let rollStiffnessFar: Double = 6

    init(scene: RealityKit.Scene) {}

    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let k = max(0, min(1, (x - a) / (b - a)))
        return k * k * (3 - 2 * k)
    }

    func update(context: SceneUpdateContext) {
        let t = Date().timeIntervalSinceReferenceDate
        // 여행의 심장박동. 오래 안 그려졌다면(백그라운드에 다녀왔다면) 여기서
        // 여행이 처음으로 되감긴다 — 다시 열었을 때 달이 눈앞에 있도록.
        MoonJourney.tick(at: t)
        for e in context.entities(matching: Self.travel, updatingSystemWhen: .rendering) {
            guard let c = e.components[MoonJourneyComponent.self] else { continue }
            e.position = MoonJourney.position(slot: c.slot, at: t)
            // 저 멀리서 떠오르고 저 멀리로 잠긴다 — 궤적이 이어지는 이음매를 가린다
            e.components.set(OpacityComponent(opacity: MoonJourney.opacity(slot: c.slot, at: t)))
        }
        // 프레임이 한 번 늦어도 튀지 않게 한 걸음의 길이를 묶어 둔다
        let dt = min(context.deltaTime, 1.0 / 30.0)
        for e in context.entities(matching: Self.rolls, updatingSystemWhen: .rendering) {
            guard var r = e.components[MoonRollComponent.self] else { continue }
            // 임계 감쇠 스프링 — 목표를 넘치지 않고 가장 빨리 닿는다
            // 목표까지 멀수록 부드러운 스프링으로 — 가까우면 손가락에 붙고, 멀면 굴러간다
            let gap = abs(r.target - r.current)
            let far = SIMD2(Self.smoothstep(20, 90, gap.x), Self.smoothstep(20, 90, gap.y))
            let w = Self.rollStiffness + (Self.rollStiffnessFar - Self.rollStiffness) * far
            let accel = -w * w * (r.current - r.target) - 2 * w * r.velocity
            r.velocity += accel * dt
            r.current += r.velocity * dt
            e.components.set(r)
            e.orientation = Moon3DView.orientation(roll: r.current.x, rollY: r.current.y)
        }
        for e in context.entities(matching: Self.suns, updatingSystemWhen: .rendering) {
            guard var s = e.components[MoonSunComponent.self] else { continue }
            let phase = s.playingSince.map { MoonSunComponent.phase(elapsed: t - $0) } ?? 1
            let target = acos(max(-1, min(1, phase)))
            let ws = Self.sunStiffness
            s.velocity += (-ws * ws * (s.angle - target) - 2 * ws * s.velocity) * dt
            s.angle += s.velocity * dt
            e.components.set(s)
            // 해는 왼쪽으로 돌아간다 → 그림자가 오른쪽에서 차오른다(2D 달과 같은 쪽).
            // 살짝 위에서 비춰 명암 경계가 기계처럼 수직이지 않게 한다.
            e.look(at: .zero, from: SIMD3<Float>(Float(-sin(s.angle)), 0.22, Float(cos(s.angle))),
                   relativeTo: nil)
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
        MoonRollComponent.registerComponent()
        MoonSunComponent.registerComponent()
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
    /// (카메라 거리 MoonJourney.cameraDistance 는 궤적 쪽과 공유한다 —
    ///  거기서도 같은 원근 축소율로 "지금 눈앞인지"를 계산하기 때문)
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
            camera.position = SIMD3<Float>(0, 0, MoonJourney.cameraDistance)
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
            light.look(at: .zero, from: SIMD3<Float>(0, 0.22, 1), relativeTo: nil)   // 보름달에서 시작
            light.components.set(MoonSunComponent(playingSince: isPlaying ? Date().timeIntervalSinceReferenceDate : nil))
            content.add(light)
            sun = light

            // 씬을 세우기 전에 여행 시계부터 맞춘다. 첫 프레임이 엉뚱한 자리에서
            // 시작하면 그 한 프레임이 깜빡임으로 보인다.
            let now = Date().timeIntervalSinceReferenceDate
            MoonJourney.tick(at: now)
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
                let d = MoonJourney.cameraDistance
                let sx = Float(sway.width) * Self.swayRange
                let sy = Float(sway.height) * Self.swayRange
                cam.look(at: SIMD3<Float>(0, 0, 0),
                         from: SIMD3<Float>(sx, -sy, d),
                         relativeTo: nil)
            }

            // 손가락 따라 굴러가는 회전 — 목표만 건네고, 움직임은 MoonJourneySystem 이 매 프레임 잇는다
            let target = SIMD2(roll, rollY)
            for (_, tilt) in tilts {
                if var r = tilt.components[MoonRollComponent.self] {
                    r.target = target
                    tilt.components.set(r)
                } else {
                    tilt.components.set(MoonRollComponent(target: target, current: target))
                    tilt.orientation = Self.orientation(roll: roll, rollY: rollY)
                }
            }

            // 재생이 켜지고 꺼지는 순간만 해에 알린다 — 그 뒤의 움직임은 시스템이 매 프레임 잇는다
            if let sun, var s = sun.components[MoonSunComponent.self], (s.playingSince != nil) != isPlaying {
                s.playingSince = isPlaying ? Date().timeIntervalSinceReferenceDate : nil
                sun.components.set(s)
            }
            sun?.light.color = Self.moonlight(tint)
            sun?.light.intensity = isPlaying ? 3_900 : 3_100
        }
        .frame(width: size * Self.frameScale, height: size * Self.frameScale)
        .allowsHitTesting(false)
        .task { await bakeAll(width: Self.previewWidth) ; await bakeAll(width: Self.textureWidth) }
        .onReceive(bodyCheck) { _ in refreshFaces() }
    }

    @State private var sun: DirectionalLight?

    /// RealityKit 은 +Y 오른손 법칙이라 각도가 양수일 때 앞면이 오른쪽으로 간다
    /// (2D 의 markX = sin(roll) 과 같다).
    static func orientation(roll: Double, rollY: Double) -> simd_quatf {
        simd_quatf(angle: Float(roll * .pi / 180), axis: SIMD3<Float>(0, 1, 0))
            * simd_quatf(angle: Float(rollY * .pi / 180), axis: SIMD3<Float>(1, 0, 0))
    }

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
