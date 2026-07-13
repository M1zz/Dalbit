//
//  SoundDetailView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/07.
//

import SwiftUI
import AVFoundation
import Combine

/**
 사용자가 Sound를 커스텀하는 View
 */
struct SoundDetailView: View {

    // MARK: - Properties
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var viewModel: CustomSoundViewModel

    let isTutorial: Bool
    @State var progress: Double = 0.0
    @State var isShowingSheet: Bool = false
    @State var originalSound: OriginalSound
    @State private var filters: [AudioFilter] = []
    @State private var selectedMoodId: String? = nil
    var editingSound: CustomSound? = nil
    var presetVariation: AudioVariation? = nil

    var isEditMode: Bool {
        editingSound != nil
    }

    var isPresetMode: Bool {
        presetVariation != nil
    }
    
    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollView {
                VStack(spacing: DS.Spacing.md) {
                    VStack(spacing: DS.Spacing.xs) {
                        Text(L.Customize.shapeSound.localized)
                            .foregroundColor(DS.Colors.textPrimary)
                            .font(DS.Font.title())
                            .padding(.top, DS.Spacing.xs)
                        Text(L.Customize.pickFeel.localized)
                            .foregroundColor(DS.Colors.textSecondary)
                            .font(DS.Font.subhead())
                    }

                    // 사운드 이미지
                    soundImageView()
                        .accessibilityHidden(true)

                    // 무드 프리셋 + 볼륨 + 음원 종류
                    moodControls()
                        .padding(.bottom, DS.Spacing.md)
                }
            }
            .dsConstrainedWidth()

            .navigationBarTitle(originalSound.name, displayMode: .inline)
            .font(.system(size: 24, weight: .bold))
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if viewModel.isPlaying {
                            viewModel.stopSound()
                        }
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(DS.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(L.A11y.backButton.localized)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {

                        isShowingSheet.toggle()
                    } label: {
                        Text(L.Common.next.localized)
                            .foregroundColor(DS.Colors.accent)
                            .font(DS.Font.subhead().weight(.semibold))
                    }
                }
            }
            .navigationBarBackButtonHidden(true)

            .navigationDestination(isPresented: $isShowingSheet) {
                SoundSaveView(originalSound: originalSound, editingSound: editingSound)
            }

            // MARK: - Life Cycle
            .onAppear() {
                if UserDefaultsManager.shared.isFirstVisit {
                    UserDefaultsManager.shared.isFirstVisit = false
                }
                DispatchQueue.main.async {
                    viewModel.sound = originalSound
                    viewModel.filters = viewModel.filterDictionary[viewModel.sound.category]!

                    // 편집 모드일 경우 기존 값 로드
                    if isEditMode, let editing = editingSound {
                        viewModel.volume = editing.audioVariation.volume
                        viewModel.pitch = editing.audioVariation.pitch
                        viewModel.interval = editing.audioVariation.interval
                        viewModel.intervalVariation = editing.audioVariation.intervalVariation
                        viewModel.volumeVariation = editing.audioVariation.volumeVariation
                        viewModel.pitchVariation = editing.audioVariation.pitchVariation
                        viewModel.filter = editing.filter
                    }
                    // 프리셋 모드일 경우 프리셋 값 로드
                    else if isPresetMode, let preset = presetVariation {
                        viewModel.volume = preset.volume
                        viewModel.pitch = preset.pitch
                        viewModel.interval = preset.interval
                        viewModel.intervalVariation = preset.intervalVariation
                        viewModel.volumeVariation = preset.volumeVariation
                        viewModel.pitchVariation = preset.pitchVariation
                        // 프리셋의 필터는 originalSound에 이미 포함되어 있음
                    }

                    if !isTutorial {
                        viewModel.play(with: viewModel.sound)
                    }
                    viewModel.isFilterChanged = {
                        viewModel.play(with: viewModel.sound)
                    }
                }
            }
            .onDisappear {
                viewModel.stopSound()
                viewModel.filters.removeAll()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    @ViewBuilder
    func soundImageView() -> some View {
        Image(originalSound.category.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 100)
            .background(Color(hex: originalSound.color))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            .padding(.horizontal, DS.Spacing.xxxl)
    }

    // MARK: - Mood Controls

    @ViewBuilder
    func moodControls() -> some View {
        VStack(spacing: DS.Spacing.md) {
            // 무드 프리셋 타일
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Spacing.sm),
                                GridItem(.flexible(), spacing: DS.Spacing.sm)],
                      spacing: DS.Spacing.sm) {
                ForEach(Self.moods) { mood in
                    moodTile(mood)
                }
            }

            // 볼륨 (유일한 미세 조정)
            volumeControl()

            // 음원 종류 (필터)
            filterControl()
        }
        .padding(.horizontal, DS.Spacing.xl)
    }

    @ViewBuilder
    private func moodTile(_ mood: SoundMood) -> some View {
        let selected = selectedMoodId == mood.id
        Button {
            applyMood(mood)
        } label: {
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: mood.icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(selected ? DS.Colors.onAccent : DS.Colors.accent)
                Text(mood.nameKey.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(selected ? DS.Colors.onAccent : DS.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(selected ? DS.Colors.accent : DS.Colors.surface)
            )
            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.nameKey.localized)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private func volumeControl() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                Text(L.Customize.volume.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.volume * 100))
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.accent)
            }
            .accessibilityHidden(true)

            Slider(value: $viewModel.volume, in: 0.1...1.0, step: 0.01)
                .tint(DS.Colors.accent)
                .accessibilityLabel(L.Customize.volume.localized)
                .accessibilityValue(String(format: "%.0f%%", viewModel.volume * 100))
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Colors.surface)
        )
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
    }

    /// 무드 적용: 파라미터를 한 번에 세팅 (재생 중이면 시각화/오디오에 바로 반영)
    private func applyMood(_ mood: SoundMood) {
        selectedMoodId = mood.id
        viewModel.interval = mood.interval
        viewModel.pitch = mood.pitch
        viewModel.intervalVariation = mood.intervalVariation
        viewModel.volumeVariation = mood.volumeVariation
        viewModel.pitchVariation = mood.pitchVariation
    }

    @ViewBuilder
    func filterControl() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 16))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 20)

                Text(L.Customize.soundType.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.textPrimary)

                Spacer()

                Text(viewModel.filter.displayName)
                    .font(DS.Font.subhead().weight(.semibold))
                    .foregroundColor(DS.Colors.accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(viewModel.filters, id: \.self) { filter in
                        filterButton(filter: filter)
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Colors.surface)
        )
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
    }

    @ViewBuilder
    func filterButton(filter: AudioFilter) -> some View {
        Button(action: {
            viewModel.filter = filter
        }) {
            Text(filter.displayName)
                .font(DS.Font.subhead().weight(.medium))
                .foregroundColor(viewModel.filter == filter ? DS.Colors.onAccent : DS.Colors.textSecondary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(viewModel.filter == filter ? DS.Colors.accent : DS.Colors.surfaceSunken)
                )
        }
        .accessibilityLabel(filter.displayName)
        .accessibilityAddTraits(viewModel.filter == filter ? [.isButton, .isSelected] : .isButton)
    }

}

// MARK: - Sound Mood Preset
/// 느낌(무드) 프리셋 — 슬라이더 대신 한 번의 탭으로 여러 파라미터를 세팅
struct SoundMood: Identifiable {
    let id: String
    let nameKey: String
    let icon: String
    let interval: Float
    let pitch: Float
    let intervalVariation: Float
    let volumeVariation: Float
    let pitchVariation: Float
}

extension SoundDetailView {
    static let moods: [SoundMood] = [
        SoundMood(id: "calm",    nameKey: L.Customize.moodCalm,    icon: "moon.stars.fill", interval: 1.8, pitch: -1.5, intervalVariation: 0.30, volumeVariation: 0.15, pitchVariation: 0.10),
        SoundMood(id: "clear",   nameKey: L.Customize.moodClear,   icon: "sparkles",        interval: 0.7, pitch:  1.0, intervalVariation: 0.10, volumeVariation: 0.05, pitchVariation: 0.00),
        SoundMood(id: "deep",    nameKey: L.Customize.moodDeep,    icon: "waveform.path",   interval: 1.5, pitch: -3.0, intervalVariation: 0.20, volumeVariation: 0.10, pitchVariation: 0.20),
        SoundMood(id: "cozy",    nameKey: L.Customize.moodCozy,    icon: "cloud.fill",      interval: 1.1, pitch: -0.5, intervalVariation: 0.25, volumeVariation: 0.20, pitchVariation: 0.15),
        SoundMood(id: "lively",  nameKey: L.Customize.moodLively,  icon: "bolt.fill",       interval: 0.5, pitch:  2.0, intervalVariation: 0.15, volumeVariation: 0.10, pitchVariation: 0.10),
        SoundMood(id: "natural", nameKey: L.Customize.moodNatural, icon: "leaf.fill",       interval: 1.0, pitch:  0.0, intervalVariation: 0.40, volumeVariation: 0.25, pitchVariation: 0.20)
    ]
}

struct SoundDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SoundDetailView(isTutorial: true, originalSound: OriginalSound(name: "물방울", filter: .WaterDrop, category: .WaterDrop))
            .environmentObject(CustomSoundViewModel())
    }
}
