//
//  Components.swift
//  RelaxOn
//
//  고요한 미니멀 디자인 시스템의 공용 컴포넌트와 View 수정자.
//  화면들은 이 컴포넌트만 조합해서 일관된 룩앤필을 유지한다.
//

import SwiftUI

// MARK: - Responsive Layout

extension DS {
    /// 넓은 화면(iPad·가로)에서 콘텐츠가 과도하게 늘어나지 않도록 하는 기준 최대 폭
    enum Layout {
        static let contentMaxWidth: CGFloat = 560
        /// 사운드 카드 그리드용 적응형 컬럼 (폰 2열, iPad 다열 자동)
        static func grid(spacing: CGFloat = DS.Spacing.md) -> [GridItem] {
            [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: spacing)]
        }
    }
}

/// 콘텐츠 폭을 제한하고 가로 중앙 정렬 (큰 화면에서 일관된 비율 유지)
struct ConstrainedWidth: ViewModifier {
    var maxWidth: CGFloat = DS.Layout.contentMaxWidth
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// 큰 화면에서 콘텐츠 최대 폭 제한 + 중앙 정렬
    func dsConstrainedWidth(_ maxWidth: CGFloat = DS.Layout.contentMaxWidth) -> some View {
        modifier(ConstrainedWidth(maxWidth: maxWidth))
    }
}

// MARK: - Screen Background

/// 모든 화면의 표준 배경 (은은한 라이트/다크 그라데이션)
struct ScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [DS.Colors.background, DS.Colors.backgroundAlt],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card

/// 큰 둥근 카드 표면. 여백 넉넉, 그림자 부드럽게.
struct CardModifier: ViewModifier {
    var padding: CGFloat = DS.Spacing.lg
    var radius: CGFloat = DS.Radius.lg
    var elevated: Bool = false

    func body(content: Content) -> some View {
        let shadow = elevated ? DS.Shadow.floating : DS.Shadow.card
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(elevated ? DS.Colors.surfaceElevated : DS.Colors.surface)
            )
            .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}

extension View {
    /// 표준 카드 스타일 적용
    func dsCard(padding: CGFloat = DS.Spacing.lg,
                radius: CGFloat = DS.Radius.lg,
                elevated: Bool = false) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, elevated: elevated))
    }
}

// MARK: - Button Styles

/// 포인트 컬러로 채운 메인 버튼 (둥글고 넉넉)
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.headline())
            .foregroundColor(DS.Colors.onAccent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.accent)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 옅은 포인트 배경의 보조 버튼
struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.headline())
            .foregroundColor(DS.Colors.accent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.accentSoft)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Section Header

/// 섹션 제목 + 선택적 액세서리(개수 등)
struct SectionHeader: View {
    let title: String
    var systemIcon: String? = nil
    var accessory: String? = nil

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let systemIcon {
                Image(systemName: systemIcon)
                    .font(DS.Font.subhead())
                    .foregroundColor(DS.Colors.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            if let accessory {
                Text(accessory)
                    .font(DS.Font.caption().weight(.semibold))
                    .foregroundColor(DS.Colors.accent)
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DS.Colors.accentSoft))
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Circular Icon Button

/// 헤더 등에 쓰는 원형 아이콘 버튼 (터치 영역 44pt 보장)
struct CircleIconButton: View {
    let systemName: String
    var active: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(active ? DS.Colors.accent : DS.Colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(active ? DS.Colors.accentSoft : DS.Colors.surfaceSunken)
                )
        }
    }
}
