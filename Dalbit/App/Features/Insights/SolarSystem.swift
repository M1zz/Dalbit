//
//  SolarSystem.swift
//  Dalbit
//
//  수·금·지·화·목·토·천·해 + 내 우주선의 공통 궤도 모델.
//
//  3D 씬(PlanetPrototypeView)과 은하 지도(GalaxyMapView)가 **같은 함수**를 쓴다.
//  그래야 지도에 찍힌 "나의 위치"가 실제로 창밖에 보이는 풍경과 일치한다.
//
//  거리·크기는 실제 비율을 그대로 쓰면(해왕성 30AU, 목성 반지름 11배) 화면에 담기지 않는다.
//  그래서 거듭제곱으로 압축했다 — 순서와 상대감은 유지되고 한 화면에 들어온다.
//

import Foundation
import simd

enum SolarBody: Int, CaseIterable, Identifiable {
    case mercury, venus, earth, mars, jupiter, saturn, uranus, neptune

    var id: Int { rawValue }

    var koreanName: String {
        switch self {
        case .mercury: return "수성"
        case .venus:   return "금성"
        case .earth:   return "지구"
        case .mars:    return "화성"
        case .jupiter: return "목성"
        case .saturn:  return "토성"
        case .uranus:  return "천왕성"
        case .neptune: return "해왕성"
        }
    }

    /// 실제 궤도 반지름(AU)
    var au: Double {
        switch self {
        case .mercury: return 0.39
        case .venus:   return 0.72
        case .earth:   return 1.00
        case .mars:    return 1.52
        case .jupiter: return 5.20
        case .saturn:  return 9.58
        case .uranus:  return 19.2
        case .neptune: return 30.05
        }
    }

    /// 실제 공전 주기(지구년)
    var years: Double {
        switch self {
        case .mercury: return 0.24
        case .venus:   return 0.62
        case .earth:   return 1.00
        case .mars:    return 1.88
        case .jupiter: return 11.9
        case .saturn:  return 29.5
        case .uranus:  return 84.0
        case .neptune: return 165.0
        }
    }

    /// 실제 반지름(지구 = 1)
    var earthRadii: Double {
        switch self {
        case .mercury: return 0.38
        case .venus:   return 0.95
        case .earth:   return 1.00
        case .mars:    return 0.53
        case .jupiter: return 11.0
        case .saturn:  return 9.14
        case .uranus:  return 3.98
        case .neptune: return 3.86
        }
    }

    // MARK: 씬 단위로 압축

    /// 궤도 반지름 (씬 단위)
    var orbitRadius: Float { Float(pow(au, 0.5) * 2.2) }
    /// 구의 반지름 (씬 단위)
    var bodyRadius: Float { Float(pow(earthRadii, 0.45) * 0.17) }
    /// 궤도 위 초기 위치 — 실제 배열이 아니라 겹쳐 보이지 않게 흩어 둔 값
    var phase: Double { Double(rawValue) * 0.85 + 0.4 }
    /// 자전 속도(라디안/초) — 가스행성이 더 빠르다(실제로도 그렇다)
    var spinSpeed: Float {
        switch self {
        case .jupiter, .saturn: return 0.10
        case .uranus, .neptune: return 0.07
        default: return 0.035
        }
    }

    var hasRings: Bool { self == .saturn }

    // MARK: 표면

    /// (낮은 지대 색, 높은 지대 색)
    var palette: (low: SIMD3<Float>, high: SIMD3<Float>) {
        switch self {
        case .mercury: return (SIMD3(0.26, 0.24, 0.23), SIMD3(0.66, 0.63, 0.60))
        case .venus:   return (SIMD3(0.60, 0.47, 0.26), SIMD3(0.96, 0.89, 0.71))
        case .earth:   return (SIMD3(0.04, 0.15, 0.40), SIMD3(0.24, 0.46, 0.22))
        case .mars:    return (SIMD3(0.33, 0.14, 0.09), SIMD3(0.80, 0.43, 0.24))
        case .jupiter: return (SIMD3(0.52, 0.38, 0.27), SIMD3(0.94, 0.86, 0.74))
        case .saturn:  return (SIMD3(0.62, 0.53, 0.35), SIMD3(0.96, 0.91, 0.76))
        case .uranus:  return (SIMD3(0.42, 0.70, 0.73), SIMD3(0.74, 0.92, 0.92))
        case .neptune: return (SIMD3(0.10, 0.22, 0.60), SIMD3(0.36, 0.54, 0.88))
        }
    }

    /// 0 = 암석 지형, 1 = 가스행성 가로 줄무늬
    var banding: Float {
        switch self {
        case .jupiter: return 0.88
        case .saturn:  return 0.78
        case .neptune: return 0.45
        case .uranus:  return 0.30
        case .venus:   return 0.35
        default:       return 0
        }
    }

    /// 이 높이를 넘으면 흰색(극관·구름)으로 섞는다. nil이면 없음.
    var snowline: Float? {
        switch self {
        case .earth: return 0.86
        case .mars:  return 0.93
        default:     return nil
        }
    }

    /// 지형 주파수 — 클수록 잘게 부서진 표면
    var frequency: Float {
        switch self {
        case .mercury: return 4.6
        case .mars:    return 3.8
        case .earth:   return 3.0
        case .jupiter, .saturn, .uranus, .neptune: return 2.0
        default:       return 2.8
        }
    }
}

enum SolarSystem {

    /// 지구가 한 바퀴 도는 데 걸리는 시간(초). 나머지는 실제 비율을 따른다.
    static let earthYearSeconds: Double = 90

    /// 궤도 위 각도
    static func angle(_ body: SolarBody, at t: Double) -> Double {
        body.phase + t * (2 * .pi) / (body.years * earthYearSeconds)
    }

    /// 3D 위치 (y = 0 평면 위의 원 궤도)
    static func position(_ body: SolarBody, at t: Double) -> SIMD3<Float> {
        let a = angle(body, at: t)
        let r = Double(body.orbitRadius)
        return SIMD3<Float>(Float(cos(a) * r), 0, Float(sin(a) * r))
    }

    // MARK: 내 우주선

    /// 우주선은 고정 궤도가 아니라 태양계 안을 천천히 배회한다.
    /// 반지름이 길게 늘었다 줄었다 하므로 행성들이 가까워졌다 멀어진다.
    static let shipAnglePeriod: Double = 300   // 한 바퀴
    static let shipRadiusPeriod: Double = 240  // 안팎으로 드나드는 주기
    static let shipHeightPeriod: Double = 170  // 위아래로 흔들리는 주기

    static func shipRadius(at t: Double) -> Double {
        7.0 + 4.6 * sin(t * 2 * .pi / shipRadiusPeriod)
    }

    static func shipAngle(at t: Double) -> Double {
        t * 2 * .pi / shipAnglePeriod
    }

    static func shipPosition(at t: Double) -> SIMD3<Float> {
        let a = shipAngle(at: t)
        let r = shipRadius(at: t)
        let y = 1.7 * sin(t * 2 * .pi / shipHeightPeriod)
        return SIMD3<Float>(Float(cos(a) * r), Float(y), Float(sin(a) * r))
    }

    /// 가장 가까운 행성과 그 거리 — 지도에 "지금 어디쯤" 을 적기 위해
    static func nearest(at t: Double) -> (body: SolarBody, distance: Float) {
        let me = shipPosition(at: t)
        var best = SolarBody.mercury
        var bestD = Float.greatestFiniteMagnitude
        for b in SolarBody.allCases {
            let d = simd_distance(me, position(b, at: t))
            if d < bestD { bestD = d; best = b }
        }
        return (best, bestD)
    }
}
