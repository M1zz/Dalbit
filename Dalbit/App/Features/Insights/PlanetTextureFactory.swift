//
//  PlanetTextureFactory.swift
//  Dalbit
//
//  행성 표면 텍스처를 코드로 생성한다. 외부 이미지 에셋이 0바이트라는 뜻이다.
//
//  · 구(球) 위의 3D 방향 벡터로 노이즈를 샘플링하므로 좌우 이음매(seam)가 생기지 않는다.
//    (2D 노이즈를 등장방형 좌표에 그대로 쓰면 u=0과 u=1이 안 맞아 세로 줄이 보인다)
//  · 같은 높이맵에서 컬러맵과 노멀맵을 함께 뽑는다. 노멀맵이 있어야 빛을 받을 때
//    분화구에 실제로 그림자가 져서 '진짜 행성' 느낌이 난다.
//

import CoreGraphics
import Foundation

enum PlanetTextureFactory {

    struct Maps {
        let color: CGImage
        let normal: CGImage
        /// 생성에 걸린 시간(초) — 프로토타입에서 비용을 눈으로 보기 위해
        let duration: TimeInterval
    }

    /// - Parameters:
    ///   - width: 등장방형 텍스처 가로. 세로는 그 절반.
    ///   - body: 행성별 색·줄무늬·주파수를 여기서 가져온다.
    static func make(width: Int, body: SolarBody, octaves: Int = 6) -> Maps? {
        let start = Date()
        let w = max(64, width)
        let h = w / 2
        let (low, high) = body.palette
        let banding = body.banding
        let snowline = body.snowline
        let freq = body.frequency
        // 행성마다 노이즈 공간의 다른 자리를 쓰게 해서 표면이 겹치지 않게
        let seed = Float(body.rawValue) * 37.4

        // 1) 높이맵
        var height = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            let lat = (Float(y) + 0.5) / Float(h)          // 0=북극, 1=남극
            let theta = lat * .pi
            let sinT = sin(theta), cosT = cos(theta)
            for x in 0..<w {
                let phi = (Float(x) + 0.5) / Float(w) * 2 * .pi
                // 구면 위의 점을 그대로 노이즈 좌표로 쓴다 → 이음매 없음
                let p = SIMD3<Float>(sinT * cos(phi), cosT, sinT * sin(phi)) * freq
                var v = fbm(p + SIMD3<Float>(seed, seed, seed), octaves: octaves)

                if banding > 0 {
                    // 가스행성: 위도 방향 줄무늬. 노이즈로 줄을 흔들어 난류처럼 보이게 한다.
                    let bands = sin((lat * 9.0 + v * 1.7) * .pi) * 0.5 + 0.5
                    v = mix(v, bands, banding)
                }
                height[y * w + x] = v
            }
        }

        // 2) 컬러맵
        var colorPx = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            let lat = (Float(y) + 0.5) / Float(h)
            // 극지방일수록 흰색이 잘 얹히게(극관)
            let polar = max(0, 1 - abs(lat - 0.5) * 2.4)
            for x in 0..<w {
                let i = y * w + x
                let t = smoothstep(0.36, 0.66, height[i])
                var c = SIMD3<Float>(mix(low.x, high.x, t),
                                     mix(low.y, high.y, t),
                                     mix(low.z, high.z, t))
                if let snowline {
                    // 높은 지대 + 극지방에 흰 눈/구름
                    let snow = smoothstep(snowline, snowline + 0.10, height[i] + (1 - polar) * 0.16)
                    c = SIMD3<Float>(mix(c.x, 0.95, snow), mix(c.y, 0.96, snow), mix(c.z, 0.98, snow))
                }
                colorPx[i * 4 + 0] = UInt8(clamping: Int(c.x * 255))
                colorPx[i * 4 + 1] = UInt8(clamping: Int(c.y * 255))
                colorPx[i * 4 + 2] = UInt8(clamping: Int(c.z * 255))
                colorPx[i * 4 + 3] = 255
            }
        }

        // 3) 노멀맵 — 높이맵의 기울기에서. 가스행성은 요철이 거의 없어야 한다.
        var normalPx = [UInt8](repeating: 0, count: w * h * 4)
        let strength: Float = banding > 0.5 ? 1.0 : 4.5
        for y in 0..<h {
            let yUp = max(0, y - 1), yDn = min(h - 1, y + 1)
            for x in 0..<w {
                let xL = (x - 1 + w) % w, xR = (x + 1) % w   // 가로는 순환
                let dx = (height[y * w + xR] - height[y * w + xL]) * strength
                let dy = (height[yDn * w + x] - height[yUp * w + x]) * strength
                let n = unitVector(SIMD3<Float>(-dx, -dy, 1))
                let i = y * w + x
                normalPx[i * 4 + 0] = UInt8(clamping: Int((n.x * 0.5 + 0.5) * 255))
                normalPx[i * 4 + 1] = UInt8(clamping: Int((n.y * 0.5 + 0.5) * 255))
                normalPx[i * 4 + 2] = UInt8(clamping: Int((n.z * 0.5 + 0.5) * 255))
                normalPx[i * 4 + 3] = 255
            }
        }

        guard let color = image(from: colorPx, width: w, height: h),
              let normal = image(from: normalPx, width: w, height: h) else { return nil }

        return Maps(color: color, normal: normal, duration: Date().timeIntervalSince(start))
    }

    /// 토성 고리 — 반지름에 따라 밝기와 투명도가 달라지는 띠. 알파가 있어야 빈 곳이 비친다.
    static func ringTexture(size: Int = 512) -> CGImage? {
        var px = [UInt8](repeating: 0, count: size * size * 4)
        let c = Float(size) / 2
        let inner: Float = 0.42, outer: Float = 0.95   // 중심 대비 비율
        for y in 0..<size {
            for x in 0..<size {
                let dx = (Float(x) + 0.5 - c) / c
                let dy = (Float(y) + 0.5 - c) / c
                let r = (dx * dx + dy * dy).squareRoot()
                var alpha: Float = 0
                var bright: Float = 0
                if r > inner && r < outer {
                    let u = (r - inner) / (outer - inner)          // 0~1
                    // 여러 개의 띠 + 카시니 간극처럼 뚫린 곳
                    let band = 0.55 + 0.45 * sin(u * 34)
                    let gap = smoothstep(0.44, 0.50, u) * (1 - smoothstep(0.54, 0.60, u))
                    alpha = band * (1 - gap) * (1 - smoothstep(0.88, 1.0, u)) * smoothstep(0.0, 0.06, u)
                    bright = 0.72 + 0.28 * band
                }
                let i = (y * size + x) * 4
                let aF = max(0, min(1, alpha)) * 0.80
                // premultipliedLast 이므로 RGB에 알파를 미리 곱해 둬야 한다
                px[i + 0] = UInt8(clamping: Int(bright * 232 * aF))
                px[i + 1] = UInt8(clamping: Int(bright * 218 * aF))
                px[i + 2] = UInt8(clamping: Int(bright * 188 * aF))
                px[i + 3] = UInt8(clamping: Int(aF * 255))
            }
        }
        return image(from: px, width: size, height: size)
    }

    // MARK: - 노이즈

    /// 여러 옥타브를 겹쳐 자연스러운 굴곡을 만든다
    private static func fbm(_ p: SIMD3<Float>, octaves: Int) -> Float {
        var sum: Float = 0, amp: Float = 0.5, freq: Float = 1, norm: Float = 0
        for _ in 0..<octaves {
            sum += valueNoise(p * freq) * amp
            norm += amp
            amp *= 0.5
            freq *= 2.07     // 정수배를 피해야 격자 무늬가 안 생긴다
        }
        return sum / max(norm, 0.0001)
    }

    private static func valueNoise(_ p: SIMD3<Float>) -> Float {
        let i = SIMD3<Float>(p.x.rounded(.down), p.y.rounded(.down), p.z.rounded(.down))
        let f = p - i
        let u = f * f * (3 - 2 * f)   // smoothstep
        let ix = Int32(i.x), iy = Int32(i.y), iz = Int32(i.z)

        func corner(_ dx: Int32, _ dy: Int32, _ dz: Int32) -> Float {
            hash(ix &+ dx, iy &+ dy, iz &+ dz)
        }
        let c000 = corner(0,0,0), c100 = corner(1,0,0)
        let c010 = corner(0,1,0), c110 = corner(1,1,0)
        let c001 = corner(0,0,1), c101 = corner(1,0,1)
        let c011 = corner(0,1,1), c111 = corner(1,1,1)

        let x00 = mix(c000, c100, u.x), x10 = mix(c010, c110, u.x)
        let x01 = mix(c001, c101, u.x), x11 = mix(c011, c111, u.x)
        return mix(mix(x00, x10, u.y), mix(x01, x11, u.y), u.z)
    }

    @inline(__always)
    private static func hash(_ x: Int32, _ y: Int32, _ z: Int32) -> Float {
        var n = UInt32(bitPattern: x &* 374_761_393 &+ y &* 668_265_263 &+ z &* 1_274_126_177)
        n = (n ^ (n >> 13)) &* 1_274_126_177
        n ^= (n >> 16)
        return Float(n) * (1.0 / Float(UInt32.max))
    }

    // MARK: - 유틸

    @inline(__always) private static func unitVector(_ v: SIMD3<Float>) -> SIMD3<Float> {
        let len = (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
        return len > 0 ? v / len : SIMD3<Float>(0, 0, 1)
    }

    @inline(__always) private static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    @inline(__always) private static func smoothstep(_ e0: Float, _ e1: Float, _ x: Float) -> Float {
        let t = min(max((x - e0) / (e1 - e0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    private static func image(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        var data = pixels
        return data.withUnsafeMutableBytes { buf -> CGImage? in
            guard let ctx = CGContext(data: buf.baseAddress,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }
            return ctx.makeImage()
        }
    }
}
