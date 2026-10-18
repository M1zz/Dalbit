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
import LeeoKit

struct SettingsView: View {

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 큰 글씨(손쉬운 사용 크기)에서는 행의 글과 스위치를 위아래로 쌓는다.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var audioManager = AudioEngineManager.shared
    // 즐겨찾기만 재생 모드 (홈의 곡 순환과 공유)
    @AppStorage("favoritesOnlyPlayback") private var favoritesOnlyPlayback = false

    @State private var showFeedback = false
    @State private var showAbout = false
    @State private var showRecap = false
    @State private var showRoadmap = false
    @State private var showWhatsNew = false
    /// 메일 앱이 없어 mailto 를 못 열었을 때 — 주소를 복사해 두었다고 알린다.
    @State private var showMailCopied = false
    /// 다시 보기용 — 설정에서 끄면 다음 진입 때 안내가 되살아난다.
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false
    @AppStorage("didShowGestureCoach") private var didShowGestureCoach = false
    @State private var showInbox = false
    @State private var showUsageStats = false
    @State private var showStability = false
    @State private var showSolarSystem = false
    @State private var showGalaxyMap = false
    // 자동 화면 어둡게 (앱 전체에 적용 — MainTabView의 .idleDimming()이 읽는다)
    @AppStorage("idleDimmingEnabled") private var idleDimmingEnabled = true
    // 홈의 달을 3D로 그릴지 (되돌릴 길)
    @AppStorage("use3DMoon") private var use3DMoon = true
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
                    displaySection()
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
        .navigationDestination(isPresented: $showAbout) {
            AboutDalbitView(
                // 안내를 되살리고 설정을 닫는다 — 홈으로 돌아가야 안내가 보이기 때문이다.
                onReplayOnboarding: {
                    didShowOnboarding = false
                    dismiss()
                },
                onReplayGestures: { didShowGestureCoach = false }
            )
        }
        .navigationDestination(isPresented: $showRecap) {
            ListeningRecapView()
        }
        .navigationDestination(isPresented: $showRoadmap) {
            RoadmapScreen()
        }
        .navigationDestination(isPresented: $showWhatsNew) {
            WhatsNewView { showWhatsNew = false }
                .navigationBarBackButtonHidden(false)
        }
        .alert(L.Support.mailCopiedTitle.localized, isPresented: $showMailCopied) {
            Button("OK") {}
        } message: {
            Text(String(format: L.Support.mailCopiedMessage.localized, DalbitSpec.developerEmail))
        }
        .navigationDestination(isPresented: $showInbox) {
            FeedbackInboxView()
        }
        .navigationDestination(isPresented: $showUsageStats) {
            UsageStatsView()
        }
        .navigationDestination(isPresented: $showSolarSystem) {
            PlanetPrototypeView()
        }
        .navigationDestination(isPresented: $showGalaxyMap) {
            GalaxyMapView()
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
            .dsGlassPanel(radius: DS.Radius.md)
        }
    }

    // MARK: - Support Section (피드백)

    @ViewBuilder
    private func displaySection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle(L.Settings.sectionDisplay.localized)

            // 잠시 안 쓰면 화면이 서서히 어두워짐 — 자는 동안 눈부시지 않게
            settingRow(icon: idleDimmingEnabled ? "moon.zzz.fill" : "sun.max",
                       iconColor: idleDimmingEnabled ? DS.Colors.accent : DS.Colors.textSecondary,
                       title: L.Settings.idleDim.localized,
                       subtitle: L.Settings.idleDimHint.localized) {
                Toggle("", isOn: $idleDimmingEnabled)
                    .labelsHidden()
                    .tint(DS.Colors.accent)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L.Settings.idleDim.localized)
            .accessibilityValue(idleDimmingEnabled ? L.Common.on.localized : L.Common.off.localized)
            .dsGlassPanel(radius: DS.Radius.md)
        }
    }

    @ViewBuilder
    private func supportSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle(L.Settings.sectionSupport.localized)

            VStack(spacing: 0) {
                // 「이 앱이 뭘 하는 앱인지」가 먼저다 — 기록과 의견은 그걸 안 다음의 이야기다.
                Button { showAbout = true } label: {
                    settingRow(icon: "book",
                               iconColor: DS.Colors.accent,
                               title: L.About.entry.localized,
                               subtitle: L.About.entryHint.localized) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.About.entry.localized)

                divider()

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

                divider()

                // 앞으로 만들 기능 — 원본은 DalbitRoadmap.swift. 의견을 보내기 전에 이미 계획에 있는지 볼 수 있게 바로 아래에 둔다.
                Button { showRoadmap = true } label: {
                    settingRow(icon: "sparkles",
                               iconColor: DS.Colors.accent,
                               title: L.Roadmap.entry.localized,
                               subtitle: L.Roadmap.entryHint.localized) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.Roadmap.entry.localized)

                divider()

                // 업데이트 소식 다시 보기 — 처음 열 때 한 번 뜬 안내를 놓친 사람을 위해.
                Button { showWhatsNew = true } label: {
                    settingRow(icon: "gift",
                               iconColor: DS.Colors.accent,
                               title: L.WhatsNew.entry.localized,
                               subtitle: String(format: L.WhatsNew.subtitle.localized, WhatsNewContent.version)) {
                        chevron()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.WhatsNew.entry.localized)

                divider()

                // 개발자에게 메일 — 의견 화면보다 길게, 사진을 붙여 쓰고 싶은 사람을 위해.
                Button(action: writeMail) {
                    settingRow(icon: "at",
                               iconColor: DS.Colors.accent,
                               title: L.Support.mail.localized,
                               subtitle: DalbitSpec.developerEmail) {
                        chevron()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.Support.mail.localized)
                .accessibilityIdentifier("settings.mail")

                divider()

                // App Store 리뷰 쓰기 — 작성 페이지로 바로 간다.
                Button(action: writeReview) {
                    settingRow(icon: "star.bubble",
                               iconColor: DS.Colors.warm,
                               title: L.Support.review.localized,
                               subtitle: L.Support.reviewHint.localized) {
                        chevron()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.Support.review.localized)
                .accessibilityIdentifier("settings.review")
            }
            .dsGlassPanel(radius: DS.Radius.md)

            // 같은 사람이 만든 다른 앱 — 잠들기 전후에 함께 쓰기 좋은 앱을 이야기로 소개한다.
            LeeoFamilySettingsRow<DalbitSpec>()
                // 눌러 들어간 '함께 쓰는 앱' 화면도 이 앱의 밤하늘 색을 입는다.
                .leeoStyle(LeeoStyle(accent: DS.Colors.accent,
                                     bg: DS.Colors.background,
                                     surface: DS.Colors.surface,
                                     surfaceAlt: DS.Colors.surfaceElevated,
                                     text: DS.Colors.textPrimary,
                                     textMuted: DS.Colors.textSecondary,
                                     textFaint: DS.Colors.textTertiary))
                .foregroundColor(DS.Colors.textPrimary)
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.sm)
                .dsGlassPanel(radius: DS.Radius.md)
        }
    }

    @ViewBuilder
    private func chevron() -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(DS.Colors.textSecondary)
    }

    /// 메일 앱으로 개발자에게. 받는 쪽이 재현할 수 있게 앱·OS 버전을 본문 끝에 붙인다.
    /// 메일 앱이 없는 기기(지운 경우)에서는 주소를 복사해 두고 그렇게 알린다.
    private func writeMail() {
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = DalbitSpec.developerEmail
        parts.queryItems = [
            URLQueryItem(name: "subject", value: String(format: L.Support.mailSubject.localized, appVersion)),
            URLQueryItem(name: "body", value: "\n\n—\n\(L.App.name.localized) \(appVersion) · iOS \(UIDevice.current.systemVersion)")
        ]
        guard let url = parts.url else { return }
        openURL(url) { accepted in
            if !accepted {
                UIPasteboard.general.string = DalbitSpec.developerEmail
                showMailCopied = true
            }
        }
    }

    /// App Store 의 이 앱 리뷰 작성 페이지(`action=write-review`).
    private func writeReview() {
        guard let id = DalbitSpec.appStoreID,
              let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") else { return }
        LeeoReviewRequest.markRequested()
        openURL(url)
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
            .dsGlassPanel(radius: DS.Radius.md)
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

                divider()

                settingRow(icon: "circle.circle",
                           iconColor: DS.Colors.accent,
                           title: "3D 달 (개발자)",
                           subtitle: "끄면 예전 2D 달로 돌아간다") {
                    Toggle("", isOn: $use3DMoon)
                        .labelsHidden()
                        .tint(DS.Colors.accent)
                }

                divider()

                Button { showSolarSystem = true } label: {
                    settingRow(icon: "globe.americas",
                               iconColor: DS.Colors.accent,
                               title: "태양계 프로토타입 (개발자)",
                               subtitle: "수·금·지·화·목·토·천·해를 배회한다") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                divider()

                Button { showGalaxyMap = true } label: {
                    settingRow(icon: "map",
                               iconColor: DS.Colors.accent,
                               title: "은하 지도 (개발자)",
                               subtitle: "내 위치·항로와 은하계에서의 자리") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .dsGlassPanel(radius: DS.Radius.md)
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
        // 손쉬운 사용 크기의 글씨에서는 글이 스위치 옆에 서너 글자씩 끊겨 쌓인다 —
        // 그때는 글을 한 줄 전체로 쓰고 스위치·화살표는 그 아래로 내린다.
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DS.Spacing.xs))
            : AnyLayout(HStackLayout(spacing: DS.Spacing.sm))
        layout {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.Font.subhead().weight(.semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !stacked { Spacer() }

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
