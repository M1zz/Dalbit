//
//  SoundPlayerFullModalView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

import SwiftUI

/**
 풀 모달 화면으로 보여지는 음원 플레이어 VIew
 */
struct SoundPlayerFullModalView: View {

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @ObservedObject private var audioManager = AudioEngineManager.shared

    @State private var showSpatialControls = false
    @State private var layerPositions: [LayerPosition] = []

    struct LayerPosition: Identifiable {
        let id = UUID()
        let layerIndex: Int
        let layerName: String
        var distance: Float
        var angle: Float
        var height: Float
    }

    var body: some View {
        VStack {
            Spacer()
            
            Image(viewModel.selectedSound?.category.imageName ?? viewModel.lastSound.category.imageName)
                .resizable()
                .scaledToFit()
                .background(Color(hex: viewModel.selectedSound?.color ?? viewModel.lastSound.color))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                .shadow(color: DS.Shadow.floating.color, radius: DS.Shadow.floating.radius, y: DS.Shadow.floating.y)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Spacing.xs)
                .accessibilityHidden(true)

            Spacer()

            Text(viewModel.selectedSound?.title ?? viewModel.lastSound.title)
                .font(DS.Font.title())
                .foregroundColor(DS.Colors.textPrimary)
            
            HStack(alignment: .center, spacing: DS.Spacing.xxxl) {

                Button {
                    viewModel.playPreviousSound()
                } label: {
                    Image(PlayerButton.fastRewind.rawValue)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(DS.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .scaledToFit()
                }
                .accessibilityLabel(L.A11y.previousSound.localized)

                Button {
                    if viewModel.isPlaying {
                        viewModel.stopSound()
                    } else {
                        viewModel.play(with: viewModel.selectedSound ?? viewModel.lastSound)
                    }
                } label: {
                    Image(viewModel.playPauseStatusImage)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(DS.Colors.onAccent)
                        .frame(width: 28, height: 28)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(DS.Colors.accent)
                                .shadow(color: DS.Shadow.floating.color, radius: DS.Shadow.floating.radius, y: DS.Shadow.floating.y)
                        )
                }
                .accessibilityLabel(viewModel.isPlaying ? L.A11y.pause.localized : L.A11y.play.localized)

                Button {
                    viewModel.playNextSound()
                } label: {
                    Image(PlayerButton.fastForward.rawValue)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(DS.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .scaledToFit()
                }
                .accessibilityLabel(L.A11y.nextSound.localized)
            }
            .frame(minWidth: 200, maxWidth: .infinity)
            .padding(.top, DS.Spacing.xxl)

            // Spatial Audio Toggle
            VStack(spacing: DS.Spacing.sm) {
                Toggle(isOn: $audioManager.isSpatialAudioEnabled) {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "spatial.audio")
                            .font(.system(size: 18))
                        Text(L.Player.spatialAudio.localized)
                            .font(DS.Font.body())
                    }
                    .foregroundColor(DS.Colors.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: DS.Colors.accent))
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                        .fill(DS.Colors.surface)
                        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
                )
                .onChange(of: audioManager.isSpatialAudioEnabled) { _, _ in
                    // 공간음향 설정 변경 시 즉시 적용을 위해 재생 중인 사운드를 재시작
                    if viewModel.isPlaying {
                        let currentSound = viewModel.selectedSound ?? viewModel.lastSound
                        viewModel.stopSound()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.play(with: currentSound)
                        }
                    }
                }

                if audioManager.isSpatialAudioEnabled {
                    Text("3D 입체 음향이 활성화되어 있습니다")
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textSecondary)

                    // 위치 조정 버튼
                    Button {
                        withAnimation {
                            showSpatialControls.toggle()
                        }
                    } label: {
                        HStack {
                            Text(L.Player.positionAdjust.localized)
                                .font(DS.Font.subhead())
                            Image(systemName: showSpatialControls ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(DS.Colors.accent)
                        .padding(.vertical, DS.Spacing.xs)
                    }
                }
            }
            .padding(.top, DS.Spacing.xl)
            .padding(.horizontal, DS.Spacing.md)

            // 레이어별 위치 조정 컨트롤
            if audioManager.isSpatialAudioEnabled && showSpatialControls {
                ScrollView {
                    VStack(spacing: DS.Spacing.sm) {
                        ForEach($layerPositions) { $position in
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                HStack {
                                    Text(String(format: L.Player.layerFormat.localized, position.layerIndex + 1, position.layerName))
                                        .font(DS.Font.subhead())
                                        .foregroundColor(DS.Colors.textPrimary)

                                    Spacer()

                                    // 레이어 제거 버튼
                                    Button(action: {
                                        removeLayer(at: position.layerIndex)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(DS.Colors.danger)
                                            .frame(width: 44, height: 44)
                                    }
                                    .accessibilityLabel("\(L.A11y.removeLayer.localized), \(position.layerName)")
                                }

                                // 거리 슬라이더
                                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                                    HStack {
                                        Text(L.Player.distance.localized)
                                            .font(DS.Font.caption())
                                        Spacer()
                                        Text("\(String(format: "%.1f", position.distance))m")
                                            .font(DS.Font.caption())
                                    }
                                    .foregroundColor(DS.Colors.textSecondary)

                                    Slider(value: $position.distance, in: 0.5...5.0, step: 0.1)
                                        .accentColor(DS.Colors.accent)
                                        .accessibilityLabel("\(position.layerName), \(L.A11y.distanceSlider.localized)")
                                        .accessibilityValue("\(String(format: "%.1f", position.distance))m")
                                        .onChange(of: position.distance) { _, newValue in
                                            audioManager.updateLayerPosition(
                                                index: position.layerIndex,
                                                distance: newValue,
                                                angle: position.angle,
                                                height: position.height
                                            )
                                        }
                                }

                                // 각도 슬라이더
                                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                                    HStack {
                                        Text(L.Player.angle.localized)
                                            .font(DS.Font.caption())
                                        Spacer()
                                        Text("\(Int(position.angle))°")
                                            .font(DS.Font.caption())
                                    }
                                    .foregroundColor(DS.Colors.textSecondary)

                                    Slider(value: $position.angle, in: 0...360, step: 5)
                                        .accentColor(DS.Colors.accent)
                                        .accessibilityLabel("\(position.layerName), \(L.A11y.angleSlider.localized)")
                                        .accessibilityValue("\(Int(position.angle))°")
                                        .onChange(of: position.angle) { _, newValue in
                                            audioManager.updateLayerPosition(
                                                index: position.layerIndex,
                                                distance: position.distance,
                                                angle: newValue,
                                                height: position.height
                                            )
                                        }
                                }

                                // 높이 슬라이더
                                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                                    HStack {
                                        Text(L.Player.height.localized)
                                            .font(DS.Font.caption())
                                        Spacer()
                                        Text("\(String(format: "%.1f", position.height))m")
                                            .font(DS.Font.caption())
                                    }
                                    .foregroundColor(DS.Colors.textSecondary)

                                    Slider(value: $position.height, in: -2.0...2.0, step: 0.1)
                                        .accentColor(DS.Colors.accent)
                                        .accessibilityLabel("\(position.layerName), \(L.A11y.heightSlider.localized)")
                                        .accessibilityValue("\(String(format: "%.1f", position.height))m")
                                        .onChange(of: position.height) { _, newValue in
                                            audioManager.updateLayerPosition(
                                                index: position.layerIndex,
                                                distance: position.distance,
                                                angle: position.angle,
                                                height: newValue
                                            )
                                        }
                                }
                            }
                            .padding(DS.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                    .fill(DS.Colors.surface)
                                    .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, y: DS.Shadow.card.y)
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                }
                .frame(maxHeight: 300)
            }

            Spacer()

        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.vertical, DS.Spacing.xxl)
        .background(ScreenBackground())

        .onAppear {
            if let selectedSound = viewModel.selectedSound {
                viewModel.lastSound = selectedSound
            }

            // 레이어 위치 정보 초기화
            initializeLayerPositions()

            if viewModel.isPlaying {
                viewModel.stopSound()
                viewModel.play(with: viewModel.selectedSound ?? viewModel.lastSound)
            } else {
                viewModel.play(with: viewModel.selectedSound ?? viewModel.lastSound)
            }
        }
        .onDisappear {
            if let selectedSound = viewModel.selectedSound {
                viewModel.lastSound = selectedSound
            }
        }
    }

    // MARK: - Helper Methods

    /// 레이어 제거
    private func removeLayer(at index: Int) {
        // AudioEngineManager의 레이어 제거 메서드 호출
        audioManager.removeLayer(at: index)

        // UI 업데이트
        withAnimation {
            initializeLayerPositions()
        }

        print("🗑️ [SoundPlayerFullModalView] 레이어 \(index) 제거")
    }

    private func initializeLayerPositions() {
        let currentSound = viewModel.selectedSound ?? viewModel.lastSound

        // 레이어 사운드인 경우에만 초기화
        guard let layers = currentSound.soundLayers, !layers.isEmpty else {
            layerPositions = []
            return
        }

        // AudioEngineManager에서 현재 레이어 위치 정보 가져오기
        let positions = audioManager.getLayerPositions()

        layerPositions = layers.enumerated().map { index, layer in
            let layerName = "\(layer.category.displayName) - \(layer.filter.displayName)"

            // 현재 위치 가져오기 (없으면 기본값 사용)
            var distance: Float = 2.0
            var angle: Float = 0.0
            var height: Float = 0.0

            if index < positions.count {
                let pos = positions[index].position
                // 직교좌표를 극좌표로 변환
                distance = sqrt(pos.x * pos.x + pos.z * pos.z)
                angle = atan2(-pos.z, pos.x) * 180.0 / .pi
                if angle < 0 {
                    angle += 360
                }
                height = pos.y
            } else {
                // 기본 원형 배치
                let totalLayers = Float(layers.count)
                angle = (360.0 / totalLayers) * Float(index)
            }

            return LayerPosition(
                layerIndex: index,
                layerName: layerName,
                distance: distance,
                angle: angle,
                height: height
            )
        }
    }
}

struct FullModalSoundPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        SoundPlayerFullModalView()
    }
}
