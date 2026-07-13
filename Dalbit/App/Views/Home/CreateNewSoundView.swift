//
//  CreateNewSoundView.swift
//  RelaxOn
//
//  Created by Claude on 2025/01/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// 새로운 사운드를 드래그 앤 드롭으로 제작하는 뷰
struct CreateNewSoundView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var customSoundViewModel: CustomSoundViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = CreateSoundViewModel()
    @State private var isTargeted = false
    @State private var showSaveAlert = false
    @State private var soundTitle = ""
    @State private var isMixing = false
    @State private var mixingProgress: Float = 0.0
    @State private var showMixingOption = false
    @State private var ripples: [RippleEffect] = []
    @State private var isPreviewPlaying: Bool = false
    @State private var showSubscription: Bool = false
    @ObservedObject private var audioManager = AudioEngineManager.shared

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        // 원본 사운드 섹션
                        originalSoundsSection()

                        // 배경음악 섹션
                        backgroundMusicSection()

                        // 볼륨 조절 섹션
                        if viewModel.selectedBackground != nil {
                            volumeControlSection()
                        }
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.md)
                    .padding(.bottom, viewModel.addedSounds.isEmpty ? DS.Spacing.lg : 120)
                }
                .frame(maxWidth: .infinity)
                .dsConstrainedWidth()
            }

            // 하단 플로팅 선택된 레이어
            if !viewModel.addedSounds.isEmpty {
                VStack {
                    Spacer()
                    floatingLayerBar()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.addedSounds.count)
            }
        }
        .navigationTitle(L.CreateSound.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    let currentCount = customSoundViewModel.customSounds.filter { !$0.isPreset }.count
                    if subscriptionManager.canCreateMoreSounds(currentCount: currentCount) {
                        showSaveAlert = true
                    } else {
                        showSubscription = true
                    }
                }) {
                    Text(L.Common.done.localized)
                        .font(DS.Font.headline())
                        .foregroundColor(viewModel.addedSounds.isEmpty ? DS.Colors.textTertiary : DS.Colors.accent)
                }
                .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                .opacity(viewModel.addedSounds.isEmpty ? 0.4 : 1.0)
                .disabled(viewModel.addedSounds.isEmpty)
            }
        }
        .trackScreen("CreateSound")
        .onDisappear {
            stopPreviewPlayback()
        }
        .alert(L.Alert.soundName.localized, isPresented: $showSaveAlert) {
            TextField(L.Alert.enterName.localized, text: $soundTitle)
            Button(L.Common.cancel.localized, role: .cancel) { }
            Button(L.Common.save.localized) {
                saveSound()
            }
        } message: {
            Text(L.CreateSound.enterSoundName.localized)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }
    }

    private func saveSound() {
        guard !viewModel.addedSounds.isEmpty else { return }

        // 재생 중인 오디오가 있다면 부드럽게 중지
        stopPreviewPlayback()

        let title = soundTitle.isEmpty ? L.SaveView.defaultSoundName.localized : soundTitle
        let mainSound = viewModel.addedSounds[0]

        // 여러 사운드 레이어 생성 (각 사운드의 커스텀 값 사용)
        let layers = viewModel.addedSounds.map { sound in
            CustomSound.SoundLayer(
                category: sound.category,
                filter: sound.filter,
                audioVariation: AudioVariation(
                    volume: sound.volume,
                    pitch: sound.pitch,
                    interval: sound.interval,
                    intervalVariation: sound.intervalVariation,
                    volumeVariation: sound.volumeVariation,
                    pitchVariation: sound.pitchVariation
                )
            )
        }

        // CustomSound 생성 (메인 사운드의 커스텀 값 사용)
        let newSound = CustomSound(
            title: title,
            category: mainSound.category,
            variation: AudioVariation(
                volume: mainSound.volume,
                pitch: mainSound.pitch,
                interval: mainSound.interval,
                intervalVariation: mainSound.intervalVariation,
                volumeVariation: mainSound.volumeVariation,
                pitchVariation: mainSound.pitchVariation
            ),
            filter: mainSound.filter,
            color: "",
            backgroundSound: viewModel.selectedBackground?.rawValue,
            backgroundVolume: viewModel.selectedBackground != nil ? viewModel.backgroundVolume : nil,
            soundLayers: layers.count > 1 ? layers : nil  // 2개 이상일 때만 레이어로 저장
        )

        print("✅ [CreateNewSound] 사운드 저장: \(title)")
        print("   - 레이어 수: \(layers.count)")
        print("   - 배경음: \(viewModel.selectedBackground?.rawValue ?? "없음")")

        // CustomSoundViewModel에 저장 (customSounds는 @Published이므로 append 시 자동으로 didSet 실행됨)
        customSoundViewModel.customSounds.append(newSound)

        // 화면 닫기
        soundTitle = ""
        dismiss()
    }


    // MARK: - Floating Layer Bar (하단 플로팅)
    @ViewBuilder
    private func floatingLayerBar() -> some View {
        VStack(spacing: 0) {
            // 리플 시각화 + 사운드 칩
            ZStack {
                // 실시간 음량에 반응하는 원형 파형 (효과음 시작/소멸 시 링)
                rippleBackground()
                    .frame(height: 96)
                    .clipped()
                    .allowsHitTesting(false)

                // 사운드 칩들
                HStack(spacing: DS.Spacing.xs) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.xxs) {
                            ForEach(viewModel.addedSounds) { sound in
                                floatingSoundChip(sound: sound)
                            }

                            // 배경음 표시
                            if let bg = viewModel.selectedBackground {
                                HStack(spacing: DS.Spacing.xxs) {
                                    Image(systemName: bg.icon)
                                        .font(.system(size: 11))
                                        .foregroundColor(DS.Colors.textSecondary)
                                    Text(bg.displayName)
                                        .font(DS.Font.caption())
                                        .foregroundColor(DS.Colors.textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, DS.Spacing.xs)
                                .padding(.vertical, DS.Spacing.xxs)
                                .background(DS.Colors.surfaceSunken)
                                .cornerRadius(DS.Radius.sm)
                            }
                        }
                    }

                    Spacer(minLength: DS.Spacing.xxs)

                    // 미리듣기 버튼
                    Button(action: {
                        togglePreviewPlayback()
                    }) {
                        Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DS.Colors.onAccent)
                            .frame(width: 44, height: 44)
                            .background(isPreviewPlaying ? DS.Colors.danger : DS.Colors.accent)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isPreviewPlaying ? L.A11y.stop.localized : L.A11y.play.localized)

                    // 레이어 수 뱃지
                    Text("\(viewModel.addedSounds.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DS.Colors.onAccent)
                        .frame(width: 28, height: 28)
                        .background(DS.Colors.accent)
                        .clipShape(Circle())

                    // 초기화 버튼
                    Button(action: {
                        stopPreviewPlayback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.addedSounds.removeAll()
                            viewModel.selectedBackground = nil
                            ripples.removeAll()
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DS.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(DS.Colors.surface)
                            .clipShape(Circle())
                            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: 0, y: DS.Shadow.card.y)
                    }
                    .accessibilityLabel("초기화")
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .shadow(color: DS.Shadow.floating.color, radius: DS.Shadow.floating.radius, x: 0, y: -4)
            )
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xs)
        }
        .onDisappear { ripples.removeAll() }
        .onReceive(audioManager.layerSoundDidPlay) { event in
            guard isPreviewPlaying else { return }
            // 효과음이 실제로 재생될 때마다 링을 생성 (시작→소멸)
            addRipple(filter: event.filter, volume: event.volume)
        }
    }

    // MARK: - Sound Chip (효과음 라벨 + 삭제)
    @ViewBuilder
    private func floatingSoundChip(sound: AddedSound) -> some View {
        Group {
            HStack(spacing: 4) {
                Image(systemName: sound.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text(sound.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // 삭제
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.removeSound(sound)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .accessibilityLabel("삭제")
            }
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xxs)
            .background(sound.color.opacity(0.85))
            .cornerRadius(DS.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(Color.white.opacity(0), lineWidth: 1.5)
            )
            .scaleEffect(1.0)
        }
    }

    // MARK: - Ripple Background (실시간 음량 동기화 원형 파형)
    @ViewBuilder
    private func rippleBackground() -> some View {
        ZStack {
            // 실시간 출력 음량에 맞춰 크기가 변하는 코어 원 — 나오는 사운드와 동기화
            Circle()
                .fill(DS.Colors.accent.opacity(0.15 + Double(audioManager.outputLevel) * 0.45))
                .frame(width: 44, height: 44)
                .scaleEffect(0.6 + CGFloat(audioManager.outputLevel) * 1.7)
                .animation(.easeOut(duration: 0.1), value: audioManager.outputLevel)

            // 효과음이 시작/소멸할 때 중앙에서 퍼지는 링
            ForEach(ripples) { ripple in
                RippleCircleView(ripple: ripple)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 효과음이 실제 재생될 때 호출 — 그 순간의 음량 크기로 링을 만들고 잠시 뒤 제거
    private func addRipple(filter: AudioFilter, volume: Float) {
        let color = viewModel.addedSounds.first(where: { $0.filter == filter })?.color ?? DS.Colors.accent
        let newRipple = RippleEffect(
            color: color,
            size: CGFloat(volume) * 80 + 30
        )
        ripples.append(newRipple)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }

    // MARK: - Preview Playback (여러 소리 동시 재생)
    private func togglePreviewPlayback() {
        if isPreviewPlaying {
            stopPreviewPlayback()
        } else {
            startPreviewPlayback()
        }
    }

    private func startPreviewPlayback() {
        guard !viewModel.addedSounds.isEmpty else { return }

        // 선택된 사운드들로 임시 CustomSound 생성
        let mainSound = viewModel.addedSounds[0]
        let layers = viewModel.addedSounds.map { sound in
            CustomSound.SoundLayer(
                category: sound.category,
                filter: sound.filter,
                audioVariation: AudioVariation(
                    volume: sound.volume,
                    pitch: sound.pitch,
                    interval: sound.interval,
                    intervalVariation: sound.intervalVariation,
                    volumeVariation: sound.volumeVariation,
                    pitchVariation: sound.pitchVariation
                )
            )
        }

        let previewSound = CustomSound(
            title: "Preview",
            category: mainSound.category,
            variation: AudioVariation(
                volume: mainSound.volume,
                pitch: mainSound.pitch,
                interval: mainSound.interval,
                intervalVariation: mainSound.intervalVariation,
                volumeVariation: mainSound.volumeVariation,
                pitchVariation: mainSound.pitchVariation
            ),
            filter: mainSound.filter,
            color: "",
            backgroundSound: viewModel.selectedBackground?.rawValue,
            backgroundVolume: viewModel.selectedBackground != nil ? viewModel.backgroundVolume : nil,
            soundLayers: layers.count > 1 ? layers : nil
        )

        customSoundViewModel.play(with: previewSound)
        audioManager.startMetering()   // 실시간 음량 측정 시작 (원형 파형 동기화)
        isPreviewPlaying = true
        print("▶️ [CreateNewSound] 미리듣기 시작 (\(viewModel.addedSounds.count)개 레이어)")
    }

    private func stopPreviewPlayback() {
        guard isPreviewPlaying else { return }
        customSoundViewModel.stopSound()
        audioManager.stopMetering()
        isPreviewPlaying = false
        print("⏹️ [CreateNewSound] 미리듣기 중지")
    }

    // MARK: - Original Sounds Section (카테고리별 정리)
    @ViewBuilder
    private func originalSoundsSection() -> some View {
        VStack(spacing: DS.Spacing.md) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(L.CreateSound.originalSounds.localized)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Colors.textPrimary)

                    HStack(spacing: DS.Spacing.xxs) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                        Text(L.CreateSound.tapToSelectMultiple.localized)
                            .font(DS.Font.caption())
                    }
                    .foregroundColor(DS.Colors.textTertiary)
                }

                Spacer()
            }

            // 카테고리별 사운드
            ForEach(SoundCategory.allCases.filter { $0 != .none }, id: \.self) { category in
                let categorySounds = viewModel.availableSounds.filter { $0.category == category }
                if !categorySounds.isEmpty {
                    soundCategorySection(category: category, sounds: categorySounds)
                }
            }
        }
        .dsCard()
    }

    // MARK: - Sound Category Section
    private func soundCategorySection(category: SoundCategory, sounds: [AvailableSound]) -> some View {
        let isLocked = subscriptionManager.isCategoryLocked(category)

        return VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            // 카테고리 헤더
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: category.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(category.themeColor)

                Text(category.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(category.themeColor)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)

                    Text("Premium")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }

                Rectangle()
                    .fill(category.themeColor.opacity(0.2))
                    .frame(height: 1)
            }

            // 사운드 그리드 (3열)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(sounds) { sound in
                    if isLocked {
                        CompactSoundCard(
                            sound: sound,
                            isSelected: false
                        ) {
                            showSubscription = true
                        }
                        .opacity(0.5)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle()),
                            alignment: .topTrailing
                        )
                    } else {
                        CompactSoundCard(
                            sound: sound,
                            isSelected: viewModel.isSoundAdded(sound)
                        ) {
                            let wasAdded = viewModel.isSoundAdded(sound)
                            viewModel.toggleSound(sound)
                            if !wasAdded {
                                startPreviewPlayback()
                            } else {
                                if viewModel.addedSounds.isEmpty {
                                    stopPreviewPlayback()
                                } else {
                                    startPreviewPlayback()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Background Music Section
    @ViewBuilder
    private func backgroundMusicSection() -> some View {
        VStack(spacing: DS.Spacing.md) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(L.CreateSound.backgroundMusic.localized)
                        .font(DS.Font.title())
                        .foregroundColor(DS.Colors.textPrimary)

                    Text(L.CreateSound.optionalAmbience.localized)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                }

                Spacer()

                if viewModel.selectedBackground != nil {
                    Button(action: {
                        withAnimation {
                            viewModel.selectedBackground = nil
                        }
                        // 미리듣기 중이면 배경음 제거하여 재시작
                        if isPreviewPlaying {
                            startPreviewPlayback()
                        }
                    }) {
                        HStack(spacing: DS.Spacing.xxs) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text(L.CreateSound.deselect.localized)
                                .font(DS.Font.subhead())
                        }
                        .foregroundColor(DS.Colors.danger)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xxs)
                        .background(DS.Colors.danger.opacity(0.1))
                        .cornerRadius(DS.Radius.sm)
                    }
                    .accessibilityLabel(L.CreateSound.deselect.localized)
                }
            }

            // 그리드
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(BackgroundSound.allCases, id: \.self) { background in
                    BackgroundMusicCard(
                        background: background,
                        isSelected: viewModel.selectedBackground == background
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedBackground = background
                        }
                        // 미리듣기 중이면 배경음 포함하여 재시작
                        if isPreviewPlaying {
                            startPreviewPlayback()
                        }
                    }
                }
            }
        }
        .dsCard()
    }

    // MARK: - Volume Control Section
    @ViewBuilder
    private func volumeControlSection() -> some View {
        VStack(spacing: DS.Spacing.md) {
            // 헤더
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(DS.Colors.accent)

                Text(L.CreateSound.backgroundMusicVolume.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.textPrimary)

                Spacer()

                Text("\(Int(viewModel.backgroundVolume * 100))%")
                    .font(DS.Font.callout())
                    .foregroundColor(DS.Colors.accent)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xxs)
                    .background(DS.Colors.accentSoft)
                    .cornerRadius(DS.Radius.sm)
            }

            // 슬라이더
            VStack(spacing: DS.Spacing.xs) {
                Slider(value: $viewModel.backgroundVolume, in: 0...1)
                    .tint(DS.Colors.accent)
                    .onChange(of: viewModel.backgroundVolume) { _, newValue in
                        // 미리듣기 중이면 오디오 엔진의 배경 볼륨도 실시간 반영
                        if isPreviewPlaying {
                            audioManager.backgroundVolume = newValue
                        }
                    }
                    .accessibilityLabel(L.A11y.volumeSlider.localized)
                    .accessibilityValue("\(Int(viewModel.backgroundVolume * 100))%")

                HStack {
                    Text(L.Common.quiet.localized)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                    Spacer()
                    Text(L.Common.loud.localized)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                }
            }
        }
        .dsCard()
    }

}

// MARK: - Background Music Card

struct BackgroundMusicCard: View {
    let background: BackgroundSound
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DS.Spacing.xs) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: background.colors.map { $0.opacity(isSelected ? 1.5 : 1.0) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: background.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? DS.Colors.onAccent : DS.Colors.textPrimary)
                }

                // 이름
                Text(background.displayName)
                    .font(DS.Font.caption())
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? DS.Colors.accent : DS.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.xxs)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(DS.Colors.surface)
                    .shadow(
                        color: isSelected ? DS.Colors.accent.opacity(0.3) : DS.Shadow.card.color,
                        radius: isSelected ? 6 : 3,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(isSelected ? DS.Colors.accent : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Sound Card (3열 그리드용)

struct CompactSoundCard: View {
    let sound: AvailableSound
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DS.Spacing.xxs) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? sound.color
                                : sound.color.opacity(0.15)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: sound.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? DS.Colors.onAccent : sound.color)

                    if isSelected {
                        Circle()
                            .stroke(DS.Colors.onAccent, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                }

                Text(sound.name)
                    .font(DS.Font.caption())
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? sound.color : DS.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, DS.Spacing.xs)
            .padding(.horizontal, DS.Spacing.xxs)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(isSelected ? sound.color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(isSelected ? sound.color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Original Sound Card

struct OriginalSoundCard: View {
    let sound: AvailableSound
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? sound.color.opacity(0.25)
                                : sound.color.opacity(0.15)
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: sound.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : sound.color)

                    // 선택 표시 체크마크
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(sound.color)
                                            .frame(width: 18, height: 18)
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 48, height: 48)
                    }
                }

                // 이름
                Text(sound.name)
                    .font(DS.Font.caption())
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? sound.color : DS.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.xxs)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(DS.Colors.surface)
                    .shadow(
                        color: isSelected ? sound.color.opacity(0.3) : (isPressed ? sound.color.opacity(0.3) : Color.black.opacity(0.06)),
                        radius: isSelected ? 8 : (isPressed ? 6 : 3),
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? sound.color : sound.color.opacity(isPressed ? 0.4 : 0.0),
                        lineWidth: isSelected ? 2.5 : 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - View Models

class CreateSoundViewModel: ObservableObject {
    @Published var availableSounds: [AvailableSound] = []
    @Published var addedSounds: [AddedSound] = []
    @Published var selectedSound: AddedSound?
    @Published var selectedBackground: BackgroundSound?
    @Published var backgroundVolume: Float = 0.3
    @Published var shouldMixAudio: Bool = true // 기본값: 믹싱

    init() {
        loadAvailableSounds()
    }

    private func loadAvailableSounds() {
        availableSounds = [
            // MARK: - WaterDrop 카테고리
            AvailableSound(
                id: "waterdrop",
                name: AudioFilter.WaterDrop.displayName,
                icon: "drop.fill",
                color: .blue,
                category: .WaterDrop,
                filter: .WaterDrop,
                duration: 1.0
            ),
            AvailableSound(
                id: "basement",
                name: AudioFilter.Basement.displayName,
                icon: "building.fill",
                color: .cyan,
                category: .WaterDrop,
                filter: .Basement,
                duration: 2.0
            ),
            AvailableSound(
                id: "cave",
                name: AudioFilter.Cave.displayName,
                icon: "moon.fill",
                color: .indigo,
                category: .WaterDrop,
                filter: .Cave,
                duration: 1.5
            ),
            AvailableSound(
                id: "pipe",
                name: AudioFilter.Pipe.displayName,
                icon: "cylinder.fill",
                color: .teal,
                category: .WaterDrop,
                filter: .Pipe,
                duration: 1.2
            ),
            AvailableSound(
                id: "sink",
                name: AudioFilter.Sink.displayName,
                icon: "rectangle.fill",
                color: .mint,
                category: .WaterDrop,
                filter: .Sink,
                duration: 1.8
            ),

            // MARK: - SingingBowl 카테고리
            AvailableSound(
                id: "bowl",
                name: AudioFilter.SingingBowl.displayName,
                icon: "circle.circle",
                color: .purple,
                category: .SingingBowl,
                filter: .SingingBowl,
                duration: 3.0
            ),
            AvailableSound(
                id: "focus",
                name: AudioFilter.Focus.displayName,
                icon: "scope",
                color: .purple.opacity(0.8),
                category: .SingingBowl,
                filter: .Focus,
                duration: 2.5
            ),
            AvailableSound(
                id: "training",
                name: AudioFilter.Training.displayName,
                icon: "figure.mind.and.body",
                color: .purple.opacity(0.7),
                category: .SingingBowl,
                filter: .Training,
                duration: 3.0
            ),
            AvailableSound(
                id: "empty",
                name: AudioFilter.Empty.displayName,
                icon: "circle.dashed",
                color: .purple.opacity(0.6),
                category: .SingingBowl,
                filter: .Empty,
                duration: 2.8
            ),
            AvailableSound(
                id: "vibration",
                name: AudioFilter.Vibration.displayName,
                icon: "waveform",
                color: .purple.opacity(0.9),
                category: .SingingBowl,
                filter: .Vibration,
                duration: 3.2
            ),
            AvailableSound(
                id: "tibetanbowl",
                name: AudioFilter.TibetanBowl.displayName,
                icon: "circle.hexagongrid.fill",
                color: .orange,
                category: .SingingBowl,
                filter: .TibetanBowl,
                duration: 3.5
            ),
            AvailableSound(
                id: "bell",
                name: AudioFilter.Bell.displayName,
                icon: "bell.fill",
                color: .yellow,
                category: .SingingBowl,
                filter: .Bell,
                duration: 2.0
            ),
            AvailableSound(
                id: "bowldeep",
                name: AudioFilter.BowlDeep.displayName,
                icon: "circle.circle.fill",
                color: .purple,
                category: .SingingBowl,
                filter: .BowlDeep,
                duration: 4.0
            ),
            AvailableSound(
                id: "bowlloud",
                name: AudioFilter.BowlLoud.displayName,
                icon: "speaker.wave.3.fill",
                color: .purple.opacity(0.85),
                category: .SingingBowl,
                filter: .BowlLoud,
                duration: 3.5
            ),

            // MARK: - Bird 카테고리
            AvailableSound(
                id: "bird",
                name: AudioFilter.Bird.displayName,
                icon: "bird.fill",
                color: .green,
                category: .Bird,
                filter: .Bird,
                duration: 2.5
            ),
            AvailableSound(
                id: "owl",
                name: AudioFilter.Owl.displayName,
                icon: "moon.stars.fill",
                color: .brown,
                category: .Bird,
                filter: .Owl,
                duration: 2.0
            ),
            AvailableSound(
                id: "woodpecker",
                name: AudioFilter.Woodpecker.displayName,
                icon: "leaf.fill",
                color: .orange,
                category: .Bird,
                filter: .Woodpecker,
                duration: 0.8
            ),
            AvailableSound(
                id: "forest",
                name: AudioFilter.Forest.displayName,
                icon: "tree.fill",
                color: .green.opacity(0.8),
                category: .Bird,
                filter: .Forest,
                duration: 3.0
            ),
            AvailableSound(
                id: "cuckoo",
                name: AudioFilter.Cuckoo.displayName,
                icon: "sun.max.fill",
                color: .yellow,
                category: .Bird,
                filter: .Cuckoo,
                duration: 1.5
            ),
            AvailableSound(
                id: "jungle",
                name: AudioFilter.Jungle.displayName,
                icon: "leaf.arrow.triangle.circlepath",
                color: .green,
                category: .Bird,
                filter: .Jungle,
                duration: 4.0
            ),
            AvailableSound(
                id: "forestbird",
                name: AudioFilter.ForestBird.displayName,
                icon: "bird",
                color: .green.opacity(0.7),
                category: .Bird,
                filter: .ForestBird,
                duration: 3.5
            ),
            AvailableSound(
                id: "springforest",
                name: AudioFilter.SpringForest.displayName,
                icon: "sun.haze.fill",
                color: .mint,
                category: .Bird,
                filter: .SpringForest,
                duration: 5.0
            ),

            // MARK: - Rain 카테고리
            AvailableSound(
                id: "softrain",
                name: AudioFilter.SoftRain.displayName,
                icon: "cloud.drizzle.fill",
                color: .cyan,
                category: .Rain,
                filter: .SoftRain,
                duration: 6.0
            ),
            AvailableSound(
                id: "cityrain",
                name: AudioFilter.CityRain.displayName,
                icon: "cloud.rain.fill",
                color: .blue,
                category: .Rain,
                filter: .CityRain,
                duration: 5.0
            ),
            AvailableSound(
                id: "rainmaker",
                name: AudioFilter.RainMaker.displayName,
                icon: "cloud.heavyrain.fill",
                color: .blue.opacity(0.8),
                category: .Rain,
                filter: .RainMaker,
                duration: 4.0
            ),

            // MARK: - Ambient 카테고리
            AvailableSound(
                id: "ambientkeys",
                name: AudioFilter.AmbientKeys.displayName,
                icon: "pianokeys",
                color: .indigo,
                category: .Ambient,
                filter: .AmbientKeys,
                duration: 8.0
            ),
            AvailableSound(
                id: "underwater",
                name: AudioFilter.Underwater.displayName,
                icon: "water.waves",
                color: .cyan.opacity(0.8),
                category: .Ambient,
                filter: .Underwater,
                duration: 6.0
            ),
            AvailableSound(
                id: "meditationpad",
                name: AudioFilter.MeditationPad.displayName,
                icon: "sparkles",
                color: .purple.opacity(0.6),
                category: .Ambient,
                filter: .MeditationPad,
                duration: 10.0
            ),
            AvailableSound(
                id: "atmosphere",
                name: AudioFilter.Atmosphere.displayName,
                icon: "waveform.path",
                color: .indigo.opacity(0.7),
                category: .Ambient,
                filter: .Atmosphere,
                duration: 8.0
            ),
            AvailableSound(
                id: "indigomusic",
                name: AudioFilter.IndigoMusic.displayName,
                icon: "music.note",
                color: .indigo,
                category: .Ambient,
                filter: .IndigoMusic,
                duration: 7.0
            ),

            // MARK: - ASMR 카테고리
            AvailableSound(
                id: "keyboard",
                name: AudioFilter.Keyboard.displayName,
                icon: "keyboard.fill",
                color: .pink,
                category: .ASMR,
                filter: .Keyboard,
                duration: 2.0
            ),
            AvailableSound(
                id: "camera",
                name: AudioFilter.Camera.displayName,
                icon: "camera.fill",
                color: .pink.opacity(0.8),
                category: .ASMR,
                filter: .Camera,
                duration: 1.0
            )
        ]
    }

    func toggleSound(_ sound: AvailableSound) {
        // 이미 추가된 사운드인지 확인
        if let existingIndex = addedSounds.firstIndex(where: { $0.filter == sound.filter }) {
            // 이미 추가되어 있으면 제거
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _ = addedSounds.remove(at: existingIndex)
            }
            print("🔄 [CreateSoundViewModel] 사운드 제거: \(sound.name)")
        } else {
            // 추가되어 있지 않으면 추가
            let newSound = AddedSound(
                id: UUID().uuidString,
                name: sound.name,
                icon: sound.icon,
                color: sound.color,
                category: sound.category,
                filter: sound.filter,
                isCustomized: false
            )

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                addedSounds.append(newSound)
            }
            print("✅ [CreateSoundViewModel] 사운드 추가: \(sound.name)")
        }
    }

    /// 사운드가 이미 추가되었는지 확인
    func isSoundAdded(_ sound: AvailableSound) -> Bool {
        return addedSounds.contains(where: { $0.filter == sound.filter })
    }

    func removeSound(_ sound: AddedSound) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            addedSounds.removeAll { $0.id == sound.id }
        }
    }

    func selectSoundForEdit(_ sound: AddedSound) {
        selectedSound = sound
        // 여기서 커스터마이징 뷰로 이동
    }
}

// MARK: - Data Models

struct AvailableSound: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let category: SoundCategory
    let filter: AudioFilter
    let duration: TimeInterval
}

struct AddedSound: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let category: SoundCategory
    let filter: AudioFilter
    var isCustomized: Bool

    // Customization values
    var volume: Float = 1.0
    var pitch: Float = 0.0
    var interval: Float = 1.0
    var intervalVariation: Float = 0.0
    var volumeVariation: Float = 0.0
    var pitchVariation: Float = 0.0
}

// MARK: - Ripple Effect
struct RippleEffect: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Ripple Circle Animation

struct RippleCircleView: View {
    let ripple: RippleEffect
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(ripple.color.opacity(0.4), lineWidth: 1.5)
            .frame(width: ripple.size, height: ripple.size)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    scale = 2.5
                    opacity = 0.0
                }
            }
    }
}

// MARK: - Preview

struct CreateNewSoundView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreateNewSoundView()
        }
    }
}
