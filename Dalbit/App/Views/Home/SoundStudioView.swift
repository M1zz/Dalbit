//
//  SoundStudioView.swift
//  RelaxOn
//
//  소리 생성 과정 개편:
//  1) "어디서 들리나요?"에서 배경음(분위기)을 먼저 고르고
//  2) 배경음이 설정되면 그 위에 올릴 효과음들을 여러 개 골라 조합한다.
//

import SwiftUI

// MARK: - Studio Layer (선택된 효과음 + 개인화 값)

/// 스튜디오에서 선택한 효과음 1개 (필터 + 카테고리 + 개인화 파라미터)
struct StudioLayer: Identifiable, Equatable {
    let filter: AudioFilter
    let category: SoundCategory
    var variation: AudioVariation
    var id: AudioFilter { filter }
}

// MARK: - Studio View

struct SoundStudioView: View {
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @ObservedObject private var audioManager = AudioEngineManager.shared   // 실시간 출력 음량(파형용)
    @Environment(\.dismiss) var dismiss

    // 선택 상태
    @State private var selectedBackground: BackgroundSound? = nil
    @State private var backgroundChosen = false            // "없음" 포함, 배경을 한 번이라도 골랐는지
    @State private var selectedLayers: [StudioLayer] = []
    @State private var editingFilter: AudioFilter? = nil   // 개인화 패널이 열린 효과음
    @State private var backgroundVolume: Float = 0.4
    @State private var effectsFocusToken = 0              // 배경 선택 시 효과음으로 스크롤 트리거

    // 리듬 두드리기(탭) 입력
    @State private var lastTapTime: Date? = nil
    @State private var tapGaps: [Double] = []
    @State private var dragBaseInterval: Float? = nil
    @State private var previewRestartWork: DispatchWorkItem?   // 미리듣기 재시작 디바운스

    // 저장
    @State private var showSaveAlert = false
    @State private var soundTitle = ""

    /// 배경음 선택지: 맨 앞에 "없음"(nil) + 8개 배경음
    private var backgroundOptions: [BackgroundSound?] {
        [nil] + BackgroundSound.allCases.map { Optional($0) }
    }

    /// 효과음 카탈로그 노출 순서
    private let categoryOrder: [SoundCategory] = [.WaterDrop, .Rain, .Bird, .SingingBowl, .Ambient, .ASMR]

    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DS.Spacing.lg) {
                        // STEP 1 — 어디서 들리나요? (배경음)
                        backgroundSection()

                        // STEP 2 — 배경을 고르면(없음 포함) 효과음 선택지가 열린다
                        if backgroundChosen {
                            VStack(spacing: DS.Spacing.lg) {
                                if selectedBackground != nil {
                                    backgroundVolumeCard()
                                }
                                effectsSection()
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, DS.Spacing.md)
                    .dsConstrainedWidth()
                }
                // 배경을 고를 때마다 원본 사운드(효과음) 섹션으로 포커스 이동
                .onChange(of: effectsFocusToken) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            proxy.scrollTo("effectsTop", anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle(L.Studio.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSaveAlert = true }) {
                    Text(L.Common.done.localized)
                        .font(DS.Font.headline())
                        .foregroundColor(canSave ? DS.Colors.accent : DS.Colors.textTertiary)
                }
                .disabled(!canSave)
            }
        }
        .alert(L.Alert.soundName.localized, isPresented: $showSaveAlert) {
            TextField(L.Alert.enterName.localized, text: $soundTitle)
            Button(L.Common.cancel.localized, role: .cancel) { }
            Button(L.Common.save.localized) { saveSound() }
        } message: {
            Text(L.CreateSound.enterSoundName.localized)
        }
        .onDisappear {
            viewModel.stopSound()
            AudioEngineManager.shared.stopBackground()
            AudioEngineManager.shared.stopMetering()
        }
    }

    /// 저장 가능 여부: 배경음만 골라도, 효과음만 골라도 저장 가능
    private var canSave: Bool {
        selectedBackground != nil || !selectedLayers.isEmpty
    }

    // MARK: - STEP 1: 어디서 들리나요? (배경음)

    @ViewBuilder
    private func backgroundSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: L.Studio.whereHeard.localized, systemIcon: "mappin.and.ellipse")
                .padding(.horizontal, DS.Spacing.screen)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Spacing.sm),
                                GridItem(.flexible(), spacing: DS.Spacing.sm)],
                      spacing: DS.Spacing.sm) {
                ForEach(Array(backgroundOptions.enumerated()), id: \.offset) { _, bg in
                    backgroundTile(bg)
                }
            }
            .padding(.horizontal, DS.Spacing.screen)
        }
    }

    @ViewBuilder
    private func backgroundTile(_ bg: BackgroundSound?) -> some View {
        let selected = backgroundChosen && selectedBackground == bg
        let icon = bg?.icon ?? "speaker.slash.fill"
        let name = bg?.displayName ?? L.Category.none.localized   // "없음"
        Button { selectBackground(bg) } label: {
            HStack(spacing: DS.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.white : DS.Colors.accent)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selected ? DS.Colors.accent : .white)
                }
                Text(name)
                    .font(DS.Font.headline())
                    .foregroundColor(selected ? DS.Colors.onAccent : DS.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(DS.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(selected ? DS.Colors.accent : DS.Colors.surface)
            )
            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - 배경음 볼륨

    @ViewBuilder
    private func backgroundVolumeCard() -> some View {
        controlCard {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(DS.Colors.accent)
                    .accessibilityHidden(true)
                Text(L.CreateSound.backgroundMusicVolume.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Text(String(format: "%.0f%%", backgroundVolume * 100))
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.accent)
            }
            Slider(value: $backgroundVolume, in: 0.0...1.0, step: 0.01)
                .tint(DS.Colors.accent)
                .accessibilityLabel(L.CreateSound.backgroundMusicVolume.localized)
                .onChange(of: backgroundVolume) { _, _ in restartPreview() }
        }
    }

    // MARK: - STEP 2: 효과음 (다중 레이어)

    @ViewBuilder
    private func effectsSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionHeader(title: L.CreateSound.originalSounds.localized, systemIcon: "plus.circle")
                .padding(.horizontal, DS.Spacing.screen)
                .id("effectsTop")   // 배경 선택 시 여기로 스크롤

            ForEach(categoryOrder, id: \.self) { cat in
                if let filters = viewModel.filterDictionary[cat], !filters.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(cat.displayName)
                            .font(DS.Font.subhead().weight(.semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                            .padding(.horizontal, DS.Spacing.screen)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Spacing.sm),
                                            GridItem(.flexible(), spacing: DS.Spacing.sm)],
                                  spacing: DS.Spacing.sm) {
                            ForEach(filters, id: \.self) { f in
                                effectTile(f, category: cat)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.screen)

                        // 이 카테고리에서 개인화 패널이 열린 효과음이 있으면 바로 아래에 표시
                        if let editing = editingFilter,
                           filters.contains(editing),
                           selectedLayers.contains(where: { $0.filter == editing }) {
                            personalizationPanel(for: editing)
                                .padding(.top, DS.Spacing.xs)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func effectTile(_ filter: AudioFilter, category: SoundCategory) -> some View {
        let on = selectedLayers.contains(where: { $0.filter == filter })
        let editing = editingFilter == filter
        Button { tapEffect(filter, category: category) } label: {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: category.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(on ? DS.Colors.onAccent : DS.Colors.accent)
                    .frame(width: 20)
                Text(filter.displayName)
                    .font(DS.Font.subhead())
                    .foregroundColor(on ? DS.Colors.onAccent : DS.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if on {
                    Image(systemName: editing ? "slider.horizontal.3" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DS.Colors.onAccent)
                }
            }
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(on ? DS.Colors.accent : DS.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(Color.white.opacity(editing ? 0.7 : 0), lineWidth: 1.5)
            )
            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(filter.displayName)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - 개인화 패널 (효과음별 볼륨·피치·간격·불규칙)

    @ViewBuilder
    private func personalizationPanel(for filter: AudioFilter) -> some View {
        if let idx = selectedLayers.firstIndex(where: { $0.filter == filter }) {
            let layer = selectedLayers[idx]
            VStack(spacing: DS.Spacing.sm) {
                // 헤더 + 제거
                HStack {
                    Image(systemName: layer.category.iconName)
                        .foregroundColor(DS.Colors.accent)
                    Text(filter.displayName)
                        .font(DS.Font.headline())
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    Button(action: { removeLayer(filter) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.Colors.danger)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel(L.Common.delete.localized)
                }

                // 두드려서 리듬(재생 간격)을 정하는 탭 입력 장치 — 두드린 대로 소리가 바뀜
                rhythmPad(idx)

                sliderRow(icon: "speaker.wave.2.fill", title: L.Customize.volume.localized,
                          value: bindingVolume(idx), range: 0.1...1.0,
                          display: String(format: "%.0f%%", layer.variation.volume * 100))

                sliderRow(icon: "tuningfork", title: L.Studio.space.localized,
                          value: bindingPitch(idx), range: -5.0...5.0,
                          display: String(format: "%+.1f", layer.variation.pitch))
            }
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Colors.surfaceSunken)
            )
            .padding(.horizontal, DS.Spacing.screen)
        }
    }

    @ViewBuilder
    private func sliderRow(icon: String, title: String, value: Binding<Float>,
                           range: ClosedRange<Float>, display: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 18)
                Text(title)
                    .font(DS.Font.caption())
                    .foregroundColor(DS.Colors.textSecondary)
                Spacer()
                Text(display)
                    .font(DS.Font.caption().weight(.bold))
                    .foregroundColor(DS.Colors.accent)
            }
            Slider(value: value, in: range) { editing in
                if !editing { restartPreview() }   // 손을 떼면 미리듣기 갱신 (드래그 중 끊김 방지)
            }
            .tint(DS.Colors.accent)
            .accessibilityLabel(title)
            .accessibilityValue(display)
        }
    }

    // 효과음별 파라미터 바인딩 (드래그 중에는 값만 갱신, 재생은 onEditingChanged에서)
    private func bindingVolume(_ idx: Int) -> Binding<Float> {
        Binding(get: { selectedLayers[idx].variation.volume },
                set: { selectedLayers[idx].variation.volume = $0 })
    }
    private func bindingPitch(_ idx: Int) -> Binding<Float> {
        Binding(get: { selectedLayers[idx].variation.pitch },
                set: { selectedLayers[idx].variation.pitch = $0 })
    }

    // MARK: - 리듬 두드리기 입력 장치

    /// 두드려서 재생 간격(리듬)을 정하고, 좌우로 끌어 미세 조정. 두드린 대로 소리가 바뀐다.
    @ViewBuilder
    private func rhythmPad(_ idx: Int) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 18)
                Text(L.Studio.interval.localized)
                    .font(DS.Font.caption())
                    .foregroundColor(DS.Colors.textSecondary)
                Spacer()
                Text(String(format: "%.1f%@", selectedLayers[idx].variation.interval, L.Customize.seconds.localized))
                    .font(DS.Font.caption().weight(.bold))
                    .foregroundColor(DS.Colors.accent)
            }

            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Colors.surface)
                VStack(spacing: DS.Spacing.xs) {
                    // 효과음과 싱크되는 실시간 파형 — 두드린 박자대로 소리가 날 때 튄다
                    RhythmWaveform(level: CGFloat(audioManager.outputLevel))
                        .frame(height: 46)
                        .padding(.horizontal, DS.Spacing.md)
                    Text(L.Studio.intervalHint.localized)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.sm)
                }
            }
            .frame(height: 104)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // 좌우로 끌기 = 간격 미세 조정 (오른쪽=길게)
                        if abs(value.translation.width) > 6 {
                            if dragBaseInterval == nil {
                                dragBaseInterval = selectedLayers[idx].variation.interval
                            }
                            let base = dragBaseInterval ?? selectedLayers[idx].variation.interval
                            let delta = Float(value.translation.width) / 160.0
                            selectedLayers[idx].variation.interval = min(8.0, max(0.2, base + delta))
                        }
                    }
                    .onEnded { value in
                        if abs(value.translation.width) <= 6 {
                            registerTap(idx)        // 탭 = 리듬 두드리기
                        } else {
                            schedulePreviewRestart() // 끌기 끝 → 소리 갱신
                        }
                        dragBaseInterval = nil
                    }
            )
            .accessibilityLabel(L.Studio.interval.localized)
            .accessibilityValue(String(format: "%.1f%@", selectedLayers[idx].variation.interval, L.Customize.seconds.localized))
        }
    }

    /// 두드린 간격을 평균내어 해당 효과음의 재생 간격으로 반영
    private func registerTap(_ idx: Int) {
        Haptics.soft()   // 두드릴 때마다 가벼운 촉각
        let now = Date()
        if let last = lastTapTime {
            let gap = now.timeIntervalSince(last)
            if gap > 8.0 {
                tapGaps = []   // 8초 넘게 쉬면 새 리듬으로 (느린 박자도 입력 가능)
            } else {
                tapGaps.append(gap)
                if tapGaps.count > 4 { tapGaps.removeFirst() }
                let avg = tapGaps.reduce(0, +) / Double(tapGaps.count)
                selectedLayers[idx].variation.interval = min(8.0, max(0.2, Float(avg)))
                schedulePreviewRestart()   // 두드린 리듬으로 소리가 바뀜
            }
        }
        lastTapTime = now
    }

    /// 미리듣기 재시작 디바운스 — 두드리는 도중엔 끊기지 않고, 멈추면 새 리듬으로 재생
    private func schedulePreviewRestart(delay: Double = 0.45) {
        previewRestartWork?.cancel()
        let work = DispatchWorkItem { restartPreview() }
        previewRestartWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: - Actions

    private func selectBackground(_ bg: BackgroundSound?) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedBackground = bg
            backgroundChosen = true
        }
        restartPreview()
        effectsFocusToken += 1   // 원본 사운드 섹션으로 포커스 이동
    }

    /// 효과음 탭: 안 골랐으면 추가하고 패널 열기, 골랐으면 패널 열고/닫기 (제거는 패널의 휴지통)
    private func tapEffect(_ filter: AudioFilter, category: SoundCategory) {
        if selectedLayers.contains(where: { $0.filter == filter }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                editingFilter = (editingFilter == filter) ? nil : filter
            }
        } else {
            let layer = StudioLayer(filter: filter, category: category,
                                    variation: AudioVariation(volume: 0.7, interval: 1.0))
            selectedLayers.append(layer)
            withAnimation(.easeInOut(duration: 0.2)) { editingFilter = filter }
            restartPreview()
        }
    }

    private func removeLayer(_ filter: AudioFilter) {
        selectedLayers.removeAll { $0.filter == filter }
        if editingFilter == filter { editingFilter = nil }
        restartPreview()
    }

    /// 현재 선택으로 CustomSound 구성
    private func buildSound(title: String) -> CustomSound {
        let layers = selectedLayers.map { l in
            CustomSound.SoundLayer(category: l.category, filter: l.filter, audioVariation: l.variation)
        }
        let main = selectedLayers.first
        return CustomSound(
            title: title,
            category: main?.category ?? .none,
            variation: main?.variation ?? AudioVariation(),
            filter: main?.filter ?? .none,
            color: "",
            backgroundSound: selectedBackground?.rawValue,
            backgroundVolume: selectedBackground != nil ? backgroundVolume : nil,
            soundLayers: layers.count > 1 ? layers : nil
        )
    }

    /// 미리듣기: 배경음만 골라도 바로 들리고, 효과음을 더하면 함께 재생된다.
    private func restartPreview() {
        guard selectedBackground != nil || !selectedLayers.isEmpty else {
            viewModel.stopSound()
            AudioEngineManager.shared.stopBackground()
            AudioEngineManager.shared.stopMetering()
            return
        }
        viewModel.play(with: buildSound(title: "Preview"))
        AudioEngineManager.shared.startMetering()   // 파형 동기화를 위한 실시간 음량 측정
    }

    private func saveSound() {
        viewModel.stopSound()
        AudioEngineManager.shared.stopBackground()
        let title = soundTitle.isEmpty ? L.SaveView.defaultSoundName.localized : soundTitle
        viewModel.customSounds.append(buildSound(title: title))
        Haptics.success()
        soundTitle = ""
        dismiss()
    }

    // MARK: - Helper

    @ViewBuilder
    private func controlCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            content()
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Colors.surface)
        )
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
        .padding(.horizontal, DS.Spacing.screen)
    }
}

// MARK: - Rhythm Waveform (효과음과 싱크되는 실시간 파형)

/// 실시간 출력 음량(level 0~1)에 반응하는 막대 파형. 두드린 박자대로 소리가 날 때 튄다.
struct RhythmWaveform: View {
    var level: CGFloat
    private let bars = 9

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<bars, id: \.self) { i in
                    let phase = Double(i) * 0.7
                    let wobble = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 3.0 + phase))
                    let amp = max(0.05, level)
                    let h = 5 + amp * 38 * CGFloat(wobble)
                    Capsule()
                        .fill(DS.Colors.accent.opacity(0.4 + Double(amp) * 0.6))
                        .frame(width: 4, height: max(5, h))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
