//
//  WaterDropVisualization.swift
//  RelaxOn
//
//  Created by Claude on 2025/01/26.
//

import SwiftUI
import Combine

// MARK: - 물방울 실시간 시각화

struct WaterDropVisualization: View {
    @ObservedObject var viewModel: CustomSoundViewModel
    @State private var drops: [WaterDrop] = []
    @State private var cancellable: AnyCancellable?
    @State private var lastDropTime = Date()

    var body: some View {
        ZStack {
            // 배경 그라데이션
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.05),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            // 물방울들
            ForEach(drops) { drop in
                WaterDropCircle(drop: drop)
            }

            // 중앙 정보 표시
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.PrimaryPurple))

                    Text(L.Player.realTimePlaying.localized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.TitleText))
                }

                // 현재 간격 표시
                Text(String(format: "%.1f초 간격", viewModel.interval))
                    .font(.system(size: 12))
                    .foregroundColor(Color(.Text).opacity(0.7))

                // 변동폭 표시
                if viewModel.intervalVariation > 0 || viewModel.volumeVariation > 0 || viewModel.pitchVariation > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 10))
                        Text(L.Player.hasVariation.localized)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.DefaultBackground).opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
        }
        .frame(height: 240)
        .onAppear {
            startVisualization()
        }
        .onDisappear {
            stopVisualization()
        }
        .onChange(of: viewModel.interval) { _, _ in
            // 간격 변경 시 시각화 재시작
            restartVisualization()
        }
    }

    func startVisualization() {
        lastDropTime = Date()

        cancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                checkAndAddDrop()
                cleanupOldDrops()
            }
    }

    func stopVisualization() {
        cancellable?.cancel()
        drops.removeAll()
    }

    func restartVisualization() {
        stopVisualization()
        startVisualization()
    }

    func checkAndAddDrop() {
        let now = Date()
        let timeSinceLastDrop = now.timeIntervalSince(lastDropTime)

        // 변동폭을 고려한 다음 간격 계산
        let baseInterval = Double(viewModel.interval)
        let variation = Double(viewModel.intervalVariation)

        var targetInterval = baseInterval
        if variation > 0 {
            let randomFactor = Double.random(in: -variation...variation)
            targetInterval = baseInterval * (1.0 + randomFactor)
            targetInterval = max(0.1, targetInterval)
        }

        // 간격이 지났으면 물방울 추가
        if timeSinceLastDrop >= targetInterval {
            addDrop()
            lastDropTime = now
        }
    }

    func addDrop() {
        // 변동폭을 고려한 볼륨 계산
        var randomizedVolume = viewModel.volume
        if viewModel.volumeVariation > 0 {
            let randomFactor = Float.random(in: -viewModel.volumeVariation...viewModel.volumeVariation)
            randomizedVolume = viewModel.volume * (1.0 + randomFactor)
            randomizedVolume = max(0.1, min(1.0, randomizedVolume))
        }

        // 변동폭을 고려한 피치 계산 (색상 변화에 사용)
        var randomizedPitch = viewModel.pitch
        if viewModel.pitchVariation > 0 {
            let randomFactor = Float.random(in: -viewModel.pitchVariation...viewModel.pitchVariation)
            randomizedPitch = viewModel.pitch + (randomFactor * 24.0)
            randomizedPitch = max(-24.0, min(24.0, randomizedPitch))
        }

        let drop = WaterDrop(
            volume: CGFloat(randomizedVolume),
            pitch: CGFloat(randomizedPitch),
            position: CGPoint(
                x: CGFloat.random(in: 80...160),
                y: 120
            )
        )

        drops.append(drop)
    }

    func cleanupOldDrops() {
        drops.removeAll { $0.createdAt.timeIntervalSinceNow < -2.5 }
    }
}

// MARK: - 물방울 데이터 모델

struct WaterDrop: Identifiable {
    let id = UUID()
    let volume: CGFloat
    let pitch: CGFloat
    let position: CGPoint
    let createdAt = Date()

    var color: Color {
        // 피치에 따라 색상 변화 (-24 ~ +24 범위)
        let normalized = (pitch + 24.0) / 48.0 // 0.0 ~ 1.0
        let hue = 0.55 + (normalized - 0.5) * 0.2 // 파란색 계열 (0.45 ~ 0.75)
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

// MARK: - 물방울 원 애니메이션

struct WaterDropCircle: View {
    let drop: WaterDrop
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .stroke(drop.color, lineWidth: 2 * drop.volume)
            .frame(width: 20 + drop.volume * 40, height: 20 + drop.volume * 40)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(drop.position)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    scale = 2.5
                    opacity = 0.0
                }
            }
    }
}

// MARK: - Preview

struct WaterDropVisualization_Previews: PreviewProvider {
    static var previews: some View {
        WaterDropVisualization(viewModel: CustomSoundViewModel())
            .environmentObject(CustomSoundViewModel())
            .background(Color(.DefaultBackground))
    }
}
