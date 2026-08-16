//
//  Components.swift
//  Dalbit
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

/// 홈(메인)과 동일한 "별이 움직이는" 우주 배경.
/// 표준 그라데이션 위에 움직이는 별(Starfield)과 가끔 지나가는 혜성·행성(CosmicEvents)을 얹는다.
/// 네비게이션으로 밀려 올라와 상위의 공유 배경이 비치지 않는 화면(설정 등)에서 사용한다.
struct StarryBackground: View {
    var body: some View {
        ZStack {
            ScreenBackground()
            Starfield().ignoresSafeArea()
            CosmicEventsView().ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Card

/// 큰 둥근 카드 표면 — **유리**. 여백 넉넉, 테두리는 머리카락 굵기.
///
/// 불투명하게 채우지 않는 이유: 이 앱의 화면은 대부분 별이 흐르는 우주 배경 위에 놓인다.
/// 카드를 단색으로 채우면 그 자리만 배경이 뚝 끊겨서, 잘 만든 배경 위에 평범한 앱을
/// 오려 붙인 것처럼 보인다. 재질(블러)로 두면 별이 카드 뒤로 지나가며 화면이 하나로 붙는다.
///
/// ⚠️ 재질만으로는 부족해서 옅은 틴트를 한 겹 얹는다 — 밝은 별이 지나가는 자리에서
///    본문 글씨의 대비가 흔들리기 때문이다. 틴트는 `surface` 색이라 라이트/다크를 따라간다.
struct CardModifier: ViewModifier {
    var padding: CGFloat = DS.Spacing.lg
    var radius: CGFloat = DS.Radius.lg
    var elevated: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(padding)
            .background {
                shape.fill(.ultraThinMaterial)
                    .overlay(shape.fill(DS.Colors.surface.opacity(elevated ? 0.55 : 0.38)))
                    .overlay(shape.strokeBorder(DS.Colors.glassStroke, lineWidth: 1))
            }
            .shadow(color: Color.black.opacity(elevated ? 0.28 : 0.20),
                    radius: elevated ? 22 : 14, x: 0, y: elevated ? 10 : 6)
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

/// 화면에서 유일하게 **꽉 채워진** 요소. 우주 배경 위에서 달 다음으로 빛나는 것이 이것 하나여야
/// 시선이 갈 곳을 잃지 않는다. 그래서 캡슐 + 그라데이션 + 은은한 발광으로 만든다.
///
/// ⚠️ 평평한 파스텔 사각형으로 되돌리지 말 것 — 배경이 어두운 우주라 파스텔 판때기는
///    스티커처럼 붕 뜨고, 흰 글씨와의 대비도 무너진다(자세한 건 `accentFillTop` 주석).
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.headline())
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.xl)
            .background(
                Capsule(style: .continuous)
                    .fill(DS.Colors.accentFill)
                    // 위 모서리에만 걸리는 얇은 하이라이트 — 면이 유리처럼 살짝 부풀어 보인다.
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(DS.Colors.glassStroke, lineWidth: 1)
                    )
            )
            // 발광. 그림자가 아니라 **빛**이라 색이 있어야 한다 — 검은 그림자를 쓰면
            // 배경이 어두워서 보이지도 않고, 떠 있는 느낌만 사라진다.
            // ⚠️ 세게 주지 말 것. 반경을 키우면 보라 후광이 버튼 아래로 넓게 번져서
            //    자기 전에 보는 화면치고 요란해진다. 떠 있다는 것만 전해지면 충분하다.
            .shadow(color: DS.Colors.accentFillBottom.opacity(configuration.isPressed ? 0.18 : 0.30),
                    radius: configuration.isPressed ? 6 : 11, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 보조 버튼 — 유리 캡슐. 주 버튼과 **형태는 같고 무게만 다르다**(채움 vs 유리).
/// 모양까지 다르면(사각형 vs 캡슐) 두 버튼이 서로 다른 앱에서 온 것처럼 보인다.
struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.headline())
            .foregroundColor(DS.Colors.accent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.xl)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule(style: .continuous).strokeBorder(DS.Colors.glassStroke, lineWidth: 1))
            }
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
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
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().strokeBorder(DS.Colors.glassStroke, lineWidth: 1))
                    }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Circular Icon Button

/// 헤더 등에 쓰는 원형 아이콘 버튼 (터치 영역 44pt 보장).
/// 켜짐/꺼짐은 **판의 색이 아니라 글리프의 색과 테두리 세기**로 구분한다 —
/// 파스텔 원판을 깔면 배경의 별이 그 자리만 사라져 버튼이 화면에서 붕 뜬다.
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
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle().strokeBorder(
                                active ? DS.Colors.accent.opacity(0.45) : Color.white.opacity(0.12),
                                lineWidth: 1
                            )
                        )
                }
        }
    }
}

// MARK: - Glass Segmented Control

/// 유리 세그먼트 컨트롤.
///
/// `.pickerStyle(.segmented)` 를 쓰지 않는 이유: UIKit 이 자기 배경을 불투명에 가깝게 칠해서,
/// 별이 흐르는 배경 위에 회색 판이 하나 얹힌 것처럼 보인다. 배경을 비치게 하려면 직접 그려야 한다.
///
/// 선택 표시는 색을 채우는 대신 **한 겹 떠오른 유리**로 한다 — 배경이 이미 화려해서
/// 여기에 색을 더하면 시선이 분산된다.
struct GlassSegmentedControl<Value: Hashable>: View {

    let items: [(value: Value, title: String)]
    @Binding var selection: Value

    /// 선택 알약이 옆으로 미끄러지도록 잇는 이름공간.
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.value) { item in
                let isSelected = item.value == selection

                Button {
                    // 스프링을 아주 짧게 — 길면 장난스러워진다.
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = item.value
                    }
                } label: {
                    Text(item.title)
                        .font(DS.Font.subhead().weight(isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .strokeBorder(DS.Colors.glassStroke, lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "selection", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(3)
        .background(
            Capsule(style: .continuous)
                // 트랙 자체도 유리 — 다만 선택 알약보다 흐려야 층이 구분된다.
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Crescent Glyph

/// 「숙면을 위한 타이머」 위에 놓이는 표식.
///
/// SF Symbol(`moon.stars.fill`)을 옅은 원판에 얹어 두었더니 두 가지가 어긋났다.
///  · 홈 화면의 **진짜 달**과 모티프가 겹치는데 완성도는 한참 낮아, 나란히 보면 조악하다.
///  · 채워진 원판은 배경의 별을 가려서, 흐르는 우주 위에 스티커를 붙인 것처럼 떠 버린다.
///
/// 그래서 채우지 않고 **빛으로만** 그린다 — 바깥 발광, 얇은 궤도선, 초승달.
/// 배경이 그대로 비치므로 별이 글리프를 지나간다.
struct CrescentGlyph: View {

    var size: CGFloat = 116

    var body: some View {
        ZStack {
            // ① 뒤쪽 발광 — 가장자리가 완전히 사라지도록 투명까지 떨어뜨린다.
            //    딱 끊기면 그 경계가 곧 원판의 테두리로 보인다.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DS.Colors.accent.opacity(0.28), DS.Colors.accent.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            // ② 궤도선 두 겹. 바깥은 거의 안 보일 만큼 얇게 — 있는 줄 모르지만 없으면 허전하다.
            Circle()
                .strokeBorder(DS.Colors.accent.opacity(0.16), lineWidth: 1)
                .frame(width: size * 0.94, height: size * 0.94)
            Circle()
                .strokeBorder(DS.Colors.accent.opacity(0.32), lineWidth: 1)
                .frame(width: size * 0.66, height: size * 0.66)

            // ③ 초승달 — 원에서 원을 빼서 만든다(그래야 두께가 균일하고 SF Symbol 티가 안 난다).
            crescent
                .frame(width: size * 0.40, height: size * 0.40)
                .shadow(color: DS.Colors.accent.opacity(0.55), radius: size * 0.10)

            // ④ 궤도 위의 작은 별 둘. 좌우로 흩어 두어 정지된 그림이 아니라 한 장면처럼 보이게.
            star(diameter: size * 0.045, opacity: 0.85)
                .offset(x: size * 0.30, y: -size * 0.24)
            star(diameter: size * 0.030, opacity: 0.55)
                .offset(x: -size * 0.28, y: size * 0.20)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// 채운 원에서 살짝 어긋난 원을 빼낸 초승달.
    private var crescent: some View {
        Circle()
            .fill(
                LinearGradient(colors: [Color.white, DS.Colors.accent],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .mask {
                // 겹치지 않는 부분만 남긴다 → 초승달.
                Circle()
                    .overlay(
                        Circle()
                            .offset(x: size * 0.115, y: -size * 0.055)
                            .blendMode(.destinationOut)
                    )
                    .compositingGroup()
            }
    }

    private func star(diameter: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: diameter, height: diameter)
            .shadow(color: Color.white.opacity(opacity * 0.8), radius: diameter)
    }
}

// MARK: - Glass Panel

/// 유리 패널 배경. 설정·통계처럼 **행/카드가 줄줄이 놓이는 화면**에서 쓴다.
///
/// `dsCard` 와 목적이 다르다: 카드는 하나가 도드라져야 해서 그림자를 지지만,
/// 이쪽은 여러 개가 붙어 있어 그림자를 지면 화면이 지저분해진다. 그래서 테두리만 두른다.
struct GlassPanelModifier: ViewModifier {
    var radius: CGFloat = DS.Radius.md
    /// 별이 지나가도 글씨가 흔들리지 않게 얹는 틴트의 세기.
    var tint: Double = 0.34

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content.background {
            shape.fill(.ultraThinMaterial)
                .overlay(shape.fill(DS.Colors.surface.opacity(tint)))
                .overlay(shape.strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }
}

extension View {
    /// 우주 배경이 비치는 유리 패널 배경 (설정·통계 행/카드용)
    func dsGlassPanel(radius: CGFloat = DS.Radius.md, tint: Double = 0.34) -> some View {
        modifier(GlassPanelModifier(radius: radius, tint: tint))
    }
}
