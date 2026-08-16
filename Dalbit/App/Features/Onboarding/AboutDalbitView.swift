//
//  AboutDalbitView.swift
//  Dalbit
//
//  「달빛 이야기」 — 왜 만들었고(효용), 만들면서 무엇을 고려했는지(제작 노트).
//  설정 → 달빛 이야기.
//
//  온보딩과 역할이 다르다.
//   · 온보딩: 잠들려는 사람이 **넘기면서** 보는 것. 짧아야 하고 건너뛸 수 있어야 한다.
//   · 이 화면: 궁금해서 **찾아온** 사람이 읽는 것. 길어도 되고, 근거를 적어도 된다.
//  그래서 같은 내용을 짧게/길게 두 번 쓰지 않고, 여기에만 자세히 적는다.
//
//  ⚠️ 여기 적힌 것은 마케팅 문구가 아니라 **실제 구현의 이유**다.
//     동작을 바꾸면 이 글도 같이 고칠 것 — 안 그러면 앱이 설명과 다르게 동작한다.
//

import SwiftUI

struct AboutDalbitView: View {

    /// 처음 안내를 다시 보여 달라는 요청. 저장은 호출부(설정)가 한다.
    var onReplayOnboarding: () -> Void
    /// 달 조작법(코치마크)을 다시 보여 달라는 요청. 홈으로 돌아갔을 때 뜬다.
    var onReplayGestures: () -> Void

    /// 조작법은 이 화면에서 바로 보여줄 수 없다(달이 여기 없다) — 눌렀다는 사실만 알린다.
    @State private var gesturesQueued = false

    var body: some View {
        ZStack {
            StarryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
                    header()
                    section(L.About.whyTitle.localized, L.About.whyBody.localized)
                    section(L.About.valueTitle.localized, L.About.valueBody.localized)
                    craftSection()
                    replaySection()
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.vertical, DS.Spacing.xl)
                .dsConstrainedWidth()
            }
        }
        .navigationTitle(L.About.title.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 조각들

    @ViewBuilder
    private func header() -> some View {
        HStack {
            Spacer()
            CrescentGlyph(size: 120)
            Spacer()
        }
        .padding(.top, DS.Spacing.sm)
    }

    /// 제목 + 본문 한 덩어리. 카드로 감싸지 않는다 — 읽는 글이라 테두리가 오히려 흐름을 끊는다.
    @ViewBuilder
    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(title)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)
            Text(markdown(body))
                .font(DS.Font.callout())
                .foregroundColor(DS.Colors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// 제작 노트 — 항목이 많아 카드로 묶는다. 여기서는 경계가 있어야 하나씩 읽힌다.
    @ViewBuilder
    private func craftSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(L.About.craftTitle.localized)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                craftNote(L.About.Craft.breathTitle, L.About.Craft.breathBody)
                craftNote(L.About.Craft.fadeTitle, L.About.Craft.fadeBody)
                craftNote(L.About.Craft.sleepTitle, L.About.Craft.sleepBody)
                craftNote(L.About.Craft.nightTitle, L.About.Craft.nightBody)
                craftNote(L.About.Craft.moonTitle, L.About.Craft.moonBody)
                craftNote(L.About.Craft.privacyTitle, L.About.Craft.privacyBody)
            }
        }
    }

    @ViewBuilder
    private func craftNote(_ titleKey: String, _ bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(titleKey.localized)
                .font(DS.Font.subhead().weight(.semibold))
                .foregroundColor(DS.Colors.textPrimary)
            Text(markdown(bodyKey.localized))
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .dsGlassPanel(radius: DS.Radius.md)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func replaySection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(L.About.replayTitle.localized)
                .font(DS.Font.headline())
                .foregroundColor(DS.Colors.textPrimary)

            VStack(spacing: 0) {
                Button(action: onReplayOnboarding) {
                    replayRow("sparkles", L.About.replayOnboarding.localized, note: nil)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(DS.Colors.separator)
                    .frame(height: 1)
                    .padding(.leading, DS.Spacing.lg + 22 + DS.Spacing.sm)

                Button {
                    onReplayGestures()
                    withAnimation { gesturesQueued = true }
                } label: {
                    replayRow("hand.tap", L.About.replayGestures.localized,
                              note: gesturesQueued ? L.About.replayDone.localized : nil)
                }
                .buttonStyle(.plain)
                .disabled(gesturesQueued)
            }
            .dsGlassPanel(radius: DS.Radius.md)
        }
    }

    @ViewBuilder
    private func replayRow(_ icon: String, _ title: String, note: String?) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(DS.Colors.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Font.subhead())
                    .foregroundColor(DS.Colors.textPrimary)
                if let note {
                    Text(note)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if note == nil {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .padding(DS.Spacing.lg)
        .contentShape(Rectangle())
    }

    /// 본문에 쓴 `**강조**` 를 살린다. 파싱에 실패하면 원문 그대로 보여준다(별표가 보일 뿐 읽기는 된다).
    private func markdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text,
                               options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
    }
}

// MARK: - Preview

struct AboutDalbitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutDalbitView(onReplayOnboarding: {}, onReplayGestures: {})
        }
    }
}
