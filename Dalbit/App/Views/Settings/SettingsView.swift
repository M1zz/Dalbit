//
//  SettingsView.swift
//  Dalbit
//
//  설정 화면 — 사운드 옵션(효과음 끄기·즐겨찾기만 재생), 피드백 보내기, 앱 정보.
//  앱 버전을 7번 탭하면 개발자 히든 모드(접수된 피드백 인박스)가 열린다.
//  (구 타이머 설정 화면을 대체 — 타이머는 홈 위로 스와이프 화면에 있다)
//

import SwiftUI
import TipKit

struct SettingsView: View {

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @ObservedObject private var audioManager = AudioEngineManager.shared
    // 즐겨찾기만 재생 모드 (홈의 곡 순환과 공유)
    @AppStorage("favoritesOnlyPlayback") private var favoritesOnlyPlayback = false

    @State private var showFeedback = false
    @State private var showRecap = false
    @State private var showInbox = false
    @State private var showUsageStats = false
    @State private var showStability = false
    // 히든 모드: 앱 버전을 7번 탭하면 개발자 도구(피드백 인박스·사용 통계)가 드러난다
    @State private var developerMode = false
    @State private var versionTapCount = 0
    @State private var versionTapResetWork: DispatchWorkItem?

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            // 홈(메인)과 동일한 별이 움직이는 우주 배경
            StarryBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    soundSection()
                    supportSection()
                    aboutSection()
                    if developerMode { developerSection() }
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.top, DS.Spacing.md)
            }
            .dsConstrainedWidth()
        }
        .navigationTitle(L.Settings.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showFeedback) {
            FeedbackView()
        }
        .navigationDestination(isPresented: $showRecap) {
            ListeningRecapView()
        }
        .navigationDestination(isPresented: $showInbox) {
            FeedbackInboxView()
        }
        .navigationDestination(isPresented: $showUsageStats) {
            UsageStatsView()
        }
        .navigationDestination(isPresented: $showStability) {
            CrashReportsView()
        }
    }

    // MARK: - Sound Section (효과음 끄기 · 즐겨찾기만 재생)

    @ViewBuilder
    private func soundSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle(L.Settings.sectionSound.localized)

            VStack(spacing: 0) {
                // 효과음(물방울·새 등 레이어 사운드) 끄기 — 배경음악만 듣고 싶을 때
                settingRow(icon: audioManager.effectsMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                           iconColor: audioManager.effectsMuted ? DS.Colors.textSecondary : DS.Colors.accent,
                           title: L.Library.effectsToggle.localized,
                           subtitle: L.Library.effectsToggleHint.localized) {
                    Toggle("", isOn: Binding(
                        get: { audioManager.effectsMuted },
                        set: { newValue in
                            audioManager.effectsMuted = newValue
                            // 직접 꺼봤으면 안내 팁은 더 이상 필요 없음
                            if newValue {
                                EffectsOffTip().invalidate(reason: .actionPerformed)
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(DS.Colors.accent)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L.Library.effectsToggle.localized)
                .accessibilityValue(audioManager.effectsMuted ? L.Common.on.localized : L.Common.off.localized)

                divider()

                // 즐겨찾기만 재생 — 달을 지그시 눌러 담아 둔 소리만 순환
                let hasFavorites = !viewModel.customSounds.filter(\.isFavorite).isEmpty
                settingRow(icon: favoritesOnlyPlayback && hasFavorites ? "heart.fill" : "heart",
                           iconColor: favoritesOnlyPlayback && hasFavorites ? DS.Colors.warm : DS.Colors.textSecondary,
                           title: L.Library.favoritesOnly.localized,
                           subtitle: hasFavorites
                               ? L.Library.favoritesOnlyHint.localized
                               : L.Library.favoritesOnlyEmpty.localized) {
                    Toggle("", isOn: $favoritesOnlyPlayback)
                        .labelsHidden()
                        .tint(DS.Colors.warm)
                        .disabled(!hasFavorites)
                }
                .opacity(hasFavorites ? 1 : 0.55)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L.Library.favoritesOnly.localized)
                .accessibilityValue(favoritesOnlyPlayback ? L.Common.on.localized : L.Common.off.localized)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.surfaceSunken)
            )
        }
    }

    // MARK: - Support Section (피드백)

    @ViewBuilder
    private func supportSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle(L.Settings.sectionSupport.localized)

            VStack(spacing: 0) {
                // 자기 기록을 본 직후가 의견을 남기기 가장 쉬운 순간이라 피드백 바로 위에 둔다.
                Button { showRecap = true } label: {
                    settingRow(icon: "moon.stars.fill",
                               iconColor: DS.Colors.accent,
                               title: L.Recap.entry.localized,
                               subtitle: L.Recap.entryHint.localized) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.Recap.entry.localized)

                divider()

                Button { showFeedback = true } label: {
                    settingRow(icon: "envelope",
                               iconColor: DS.Colors.accent,
                               title: L.Feedback.entry.localized,
                               subtitle: L.Feedback.entryHint.localized) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.Feedback.entry.localized)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.surfaceSunken)
            )
        }
    }

    // MARK: - About Section (앱 버전 · 히든 모드)

    @ViewBuilder
    private func aboutSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle(L.Settings.sectionAbout.localized)

            // 앱 버전 — 7번 연속 탭하면 개발자 인박스(접수된 피드백)가 열린다
            Button(action: versionTapped) {
                settingRow(icon: "moon.stars",
                           iconColor: DS.Colors.textSecondary,
                           title: L.Settings.version.localized,
                           subtitle: nil) {
                    Text(appVersion)
                        .font(DS.Font.subhead())
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.surfaceSunken)
            )
            .accessibilityLabel("\(L.Settings.version.localized) \(appVersion)")
        }
    }

    /// 개발자 전용 — 버전을 7번 탭하면 드러난다.
    /// 머리말을 두지 않는다. 행마다 "(개발자)"가 붙어 있어 한 번 더 말할 필요가 없다.
    @ViewBuilder
    private func developerSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            VStack(spacing: 0) {
                Button { showUsageStats = true } label: {
                    settingRow(icon: "chart.bar.xaxis",
                               iconColor: DS.Colors.accent,
                               title: L.Stats.entry.localized,
                               subtitle: L.Stats.entryHint.localized) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                divider()

                Button { showStability = true } label: {
                    settingRow(icon: "exclamationmark.triangle",
                               iconColor: DS.Colors.accent,
                               title: L.Stability.entry.localized,
                               subtitle: L.Stability.entryHint.localized) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                divider()

                Button { showInbox = true } label: {
                    settingRow(icon: "tray.full",
                               iconColor: DS.Colors.accent,
                               title: L.Stats.inboxEntry.localized,
                               subtitle: nil) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.surfaceSunken)
            )
        }
    }

    /// 앱 버전 7번 탭 → 히든 개발자 모드. 2초 쉬면 카운트 리셋.
    private func versionTapped() {
        versionTapCount += 1
        versionTapResetWork?.cancel()
        if versionTapCount >= 7 {
            versionTapCount = 0
            Haptics.light()
            // 바로 인박스로 보내지 않고 도구 묶음을 드러낸다 — 통계와 인박스 둘 다 있어서다.
            withAnimation { developerMode = true }
        } else {
            let work = DispatchWorkItem { versionTapCount = 0 }
            versionTapResetWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
        }
    }

    // MARK: - Row Building Blocks

    @ViewBuilder
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.caption().weight(.semibold))
            .foregroundColor(DS.Colors.textTertiary)
            .padding(.leading, DS.Spacing.xs)
    }

    @ViewBuilder
    private func settingRow<Trailing: View>(icon: String,
                                            iconColor: Color,
                                            title: String,
                                            subtitle: String?,
                                            @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Font.subhead().weight(.semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                }
            }

            Spacer()

            trailing()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle()
            .fill(DS.Colors.separator)
            .frame(height: 1)
            .padding(.leading, DS.Spacing.lg + 22 + DS.Spacing.sm)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { SettingsView() }
            .environmentObject(CustomSoundViewModel())
            .preferredColorScheme(.dark)
    }
}
