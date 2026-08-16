//
//  InsightComponents.swift
//  Dalbit
//
//  개발자 대시보드(사용 통계·안정성)가 공유하는 조각들.
//  두 화면이 같은 카드·구분선·빈 상태를 각자 들고 있었는데, 한쪽만 고치면 나란히 놓았을 때
//  어긋나 보인다. 여기 한 곳만 고치면 둘 다 따라오도록 모아 둔다.
//
//  ⚠️ 여기 있는 것은 **개발자 화면 전용**이다. 사용자 화면은 DesignSystem 의 컴포넌트를 쓴다.
//     둘을 섞으면 개발자 화면 사정에 맞춘 변경이 사용자 화면까지 흔든다.
//

import SwiftUI

/// 제목 + 부연 + 내용 한 덩어리. 이 대시보드의 기본 단위다.
struct InsightCard<Content: View>: View {
    let title: String
    var note: String?
    @ViewBuilder let content: () -> Content

    init(_ title: String, note: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.note = note
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DS.Font.caption().weight(.semibold))
                    .foregroundColor(DS.Colors.textTertiary)
                if let note {
                    Text(note)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                        .opacity(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, DS.Spacing.xs)

            // ⚠️ 안쪽 여백을 줄이지 말 것. 이 화면은 잔글씨와 두 칸 표가 빽빽하게 들어차서,
            //    여백이 조금만 좁아도 글자가 카드 테두리에 붙어 답답해 보인다.
            //    바깥 화면 여백(screen)보다 카드 안이 좁으면 특히 그렇다.
            VStack(alignment: .leading, spacing: DS.Spacing.md, content: content)
                .padding(DS.Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsGlassPanel(radius: DS.Radius.lg)
        }
    }
}

/// 카드 안에서 성격이 다른 묶음을 가르는 선.
struct InsightDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Colors.textTertiary.opacity(0.15))
            .frame(height: 1)
    }
}

/// 숫자를 어떻게 읽어야 하는지 덧붙이는 잔글씨.
/// ⚠️ 줄바꿈이 잘리지 않게 `fixedSize` 를 건다 — 이 자리 문장은 대체로 길다.
struct InsightFootnote: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(DS.Font.caption())
            .foregroundColor(DS.Colors.textTertiary)
            .opacity(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 아직 데이터가 없을 때. 신규 앱은 이 상태로 오래 머문다.
struct InsightEmptyRow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(DS.Font.subhead())
            .foregroundColor(DS.Colors.textTertiary)
    }
}

struct InsightLoadingRow: View {
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            ProgressView()
            Text(L.Common.loading.localized)
                .font(DS.Font.subhead())
                .foregroundColor(DS.Colors.textSecondary)
        }
        .padding(.top, DS.Spacing.xxl)
    }
}

/// 허브를 못 읽었을 때. **원인을 같이 적어 준다** — 이 화면이 비는 이유는 거의 항상
/// 스키마 미배포나 read 권한이고, 그걸 모르면 수집이 고장 난 것으로 오해한다.
struct InsightErrorBanner: View {
    let message: String
    init(_ message: String) { self.message = message }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .font(DS.Font.subhead())
                .foregroundColor(DS.Colors.danger)
            Text(L.Stats.permissionHint.localized)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsGlassPanel(radius: DS.Radius.md)
    }
}
