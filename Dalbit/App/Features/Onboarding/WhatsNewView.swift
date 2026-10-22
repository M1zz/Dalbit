//
//  WhatsNewView.swift
//  Dalbit
//
//  업데이트 뒤 처음 열 때 **한 번** 뜨는 "새로 생긴 것" 시트. 설정 ▸ 지원 에서 다시 볼 수 있다.
//
//  ⚠️ 처음 받은 사람에게는 띄우지 않는다. 그 사람은 첫 실행 안내(OnboardingView)가 맞이하고,
//     안내를 아직 안 본 사람에게 "새로워졌어요"는 무슨 말인지 알 수 없는 말이다.
//     판단은 `WhatsNewGate.decide` 한 곳에서만 한다(순수 함수 — DalbitTests 가 지킨다).
//
//  ⚠️ 내용을 바꾸면 `WhatsNewContent.version` 도 올린다. 안 올리면 이미 본 사람으로
//     기록된 사용자는 새 안내를 한 번도 못 본다.
//

import SwiftUI

/// 이 안내가 소개하는 버전. 무관한 버전 올림에서는 다시 뜨지 않도록 앱 버전이 아니라 내용 기준으로 고정한다.
enum WhatsNewContent {
    static let version = "4.1.1"

    /// 마지막으로 본 안내 버전을 담는 키 (`@AppStorage`).
    static let lastSeenKey = "whatsNew.lastSeenVersion"

    struct Item: Identifiable {
        let id: String
        let symbol: String
        let titleKey: String
        let detailKey: String
    }

    /// 이번 버전에 실제로 들어간, 쓰는 사람이 알아챌 만한 것만.
    static let items: [Item] = [
        Item(id: "moon3d", symbol: "moon.stars.fill",
             titleKey: L.WhatsNew.moonTitle, detailKey: L.WhatsNew.moonDetail),
        Item(id: "dimming", symbol: "moon.zzz.fill",
             titleKey: L.WhatsNew.dimTitle, detailKey: L.WhatsNew.dimDetail),
        Item(id: "comfort", symbol: "accessibility",
             titleKey: L.WhatsNew.comfortTitle, detailKey: L.WhatsNew.comfortDetail),
        Item(id: "japanese", symbol: "character.bubble",
             titleKey: L.WhatsNew.japaneseTitle, detailKey: L.WhatsNew.japaneseDetail),
        Item(id: "contact", symbol: "envelope",
             titleKey: L.WhatsNew.contactTitle, detailKey: L.WhatsNew.contactDetail)
    ]
}

/// 앱을 연 사람에게 무엇을 보여 줄지 — 첫 실행 안내와 새 기능 안내가 서로 엇갈리지 않게 한 곳에서 정한다.
enum WhatsNewGate: Equatable {
    /// 처음 온 사람 — 안내는 띄우지 않고 이번 버전을 본 것으로만 적어 둔다.
    case markSeenSilently
    /// 쓰던 사람인데 이번 안내를 아직 못 봤다 — 한 번 띄운다.
    case show
    /// 이미 봤다.
    case nothing

    /// - Parameters:
    ///   - hasCompletedOnboarding: 첫 실행 안내를 끝냈는가(= 이 기기에서 앱을 써 본 사람인가).
    ///   - lastSeenVersion: 마지막으로 본 안내 버전. 본 적 없으면 빈 문자열.
    ///   - currentVersion: 지금 안내 버전.
    static func decide(hasCompletedOnboarding: Bool,
                       lastSeenVersion: String,
                       currentVersion: String = WhatsNewContent.version) -> WhatsNewGate {
        if lastSeenVersion == currentVersion { return .nothing }
        return hasCompletedOnboarding ? .show : .markSeenSilently
    }
}

struct WhatsNewView: View {
    var onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            StarryBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DS.Spacing.xl) {
                        VStack(spacing: DS.Spacing.sm) {
                            CrescentGlyph(size: 88)
                                .padding(.top, DS.Spacing.xxl)
                                .accessibilityHidden(true)

                            Text(L.WhatsNew.title.localized)
                                .font(DS.Font.title())
                                .foregroundColor(DS.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)

                            Text(String(format: L.WhatsNew.subtitle.localized, WhatsNewContent.version))
                                .font(DS.Font.callout())
                                .foregroundColor(DS.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: DS.Spacing.lg) {
                            ForEach(WhatsNewContent.items) { item in
                                featureRow(item)
                            }
                        }
                        .padding(DS.Spacing.lg)
                        .dsGlassPanel(radius: DS.Radius.lg)
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.bottom, DS.Spacing.lg)
                }

                Button(action: onClose) {
                    Text(L.WhatsNew.done.localized)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.vertical, DS.Spacing.lg)
                .accessibilityIdentifier("whatsNew.done")
            }
            .dsConstrainedWidth()
        }
    }

    @ViewBuilder
    private func featureRow(_ item: WhatsNewContent.Item) -> some View {
        // 큰 글씨에서는 아이콘을 글 위로 올려 글이 한 줄에 서너 글자씩 끊기지 않게 한다.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DS.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .top, spacing: DS.Spacing.md))
        layout {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundColor(DS.Colors.accent)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.titleKey.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.detailKey.localized)
                    .font(DS.Font.subhead())
                    .foregroundColor(DS.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(onClose: {})
            .preferredColorScheme(.dark)
    }
}
