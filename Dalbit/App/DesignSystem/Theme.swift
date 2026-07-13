//
//  Theme.swift
//  RelaxOn
//
//  고요한 미니멀(Calm Minimal) 디자인 시스템의 기반 토큰.
//  색상 · 간격 · 라운드 · 그림자 · 타이포그래피를 한 곳에서 관리한다.
//  라이트/다크 모드에 모두 대응한다.
//

import SwiftUI
import UIKit

// MARK: - Design System Namespace

enum DS {

    // MARK: Spacing (8pt 그리드 기반)
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        /// 화면 좌우 표준 여백 (넉넉하게)
        static let screen: CGFloat = 24
    }

    // MARK: Corner Radius (큰 둥근 모서리)
    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let pill: CGFloat = 999
    }

    // MARK: Colors (라이트/다크 적응형, 부드러운 파스텔)
    enum Colors {
        /// 화면 기본 배경
        static let background = Color(light: 0xF6F5FB, dark: 0x121019)
        /// 배경 위 살짝 변주된 그라데이션 끝색
        static let backgroundAlt = Color(light: 0xEFEDF8, dark: 0x171426)
        /// 카드/표면
        static let surface = Color(light: 0xFFFFFF, dark: 0x1E1B2C)
        /// 한 단계 더 올라온 표면
        static let surfaceElevated = Color(light: 0xFFFFFF, dark: 0x262236)
        /// 은은하게 눌린 표면 (입력창, 칩 비선택 등)
        static let surfaceSunken = Color(light: 0xEDEBF6, dark: 0x201D30)

        /// 포인트 컬러 (부드러운 라벤더/페리윙클)
        static let accent = Color(light: 0x6F6AD6, dark: 0xA8A4F2)
        /// 포인트의 옅은 배경
        static let accentSoft = Color(light: 0xECEAFB, dark: 0x2B2742)
        /// 보조 포인트 (따뜻한 살구)
        static let warm = Color(light: 0xE9A77C, dark: 0xE9A77C)

        /// 텍스트
        static let textPrimary = Color(light: 0x1B1A2E, dark: 0xF3F2FA)
        static let textSecondary = Color(light: 0x6A6880, dark: 0xAFADC2)
        static let textTertiary = Color(light: 0x9B99AD, dark: 0x726F86)
        /// 포인트 위에 올라가는 텍스트
        static let onAccent = Color.white

        /// 구분선/테두리
        static let separator = Color(light: 0xE7E5F1, dark: 0x322E46)

        /// 상태색
        static let success = Color(light: 0x4FAE84, dark: 0x6FD3A6)
        static let danger = Color(light: 0xE0685F, dark: 0xF08A82)
    }

    // MARK: Shadow
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat

        /// 카드용 부드러운 그림자
        static let card = Shadow(color: Color.black.opacity(0.06), radius: 18, y: 8)
        /// 떠 있는 버튼/플레이어용
        static let floating = Shadow(color: Color.black.opacity(0.10), radius: 24, y: 12)
    }

    // MARK: Typography (SF Rounded, Dynamic Type 대응)
    enum Font {
        static func largeTitle() -> SwiftUI.Font { .system(.largeTitle, design: .rounded).weight(.bold) }
        static func title() -> SwiftUI.Font { .system(.title2, design: .rounded).weight(.bold) }
        static func headline() -> SwiftUI.Font { .system(.headline, design: .rounded).weight(.semibold) }
        static func body() -> SwiftUI.Font { .system(.body, design: .rounded) }
        static func callout() -> SwiftUI.Font { .system(.callout, design: .rounded) }
        static func subhead() -> SwiftUI.Font { .system(.subheadline, design: .rounded) }
        static func caption() -> SwiftUI.Font { .system(.caption, design: .rounded) }
    }
}

// MARK: - Adaptive Color Helper

extension Color {
    /// 라이트/다크 모드용 16진수 색상으로 적응형 컬러 생성
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(rgb: dark)
                : UIColor(rgb: light)
        })
    }
}

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
