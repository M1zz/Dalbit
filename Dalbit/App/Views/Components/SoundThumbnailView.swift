//
//  SoundThumbnailView.swift
//  RelaxOn
//
//  Created by Claude on 2025/12/16.
//

import SwiftUI

/// 사운드 레이어들을 시각화한 썸네일 뷰
struct SoundThumbnailView: View {
    let sound: CustomSound
    let size: CGFloat

    private var layers: [LayerInfo] {
        var result: [LayerInfo] = []

        // soundLayers가 있으면 사용
        if let soundLayers = sound.soundLayers, !soundLayers.isEmpty {
            for layer in soundLayers {
                result.append(LayerInfo(
                    icon: iconForFilter(layer.filter),
                    color: colorForCategory(layer.category)
                ))
            }
        } else {
            // 단일 사운드
            result.append(LayerInfo(
                icon: iconForFilter(sound.filter),
                color: colorForCategory(sound.category)
            ))
        }

        // 배경음 추가
        if let backgroundName = sound.backgroundSound,
           let background = BackgroundSound.from(backgroundName) {
            result.append(LayerInfo(
                icon: background.icon,
                color: .gray,
                isBackground: true
            ))
        }

        return result
    }

    var body: some View {
        ZStack {
            // 배경 그라데이션
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // 레이어 아이콘들
            if layers.count == 1 {
                singleLayerView(layers[0])
            } else if layers.count == 2 {
                twoLayersView()
            } else if layers.count == 3 {
                threeLayersView()
            } else {
                multipleLayersView()
            }
        }
    }

    // MARK: - Single Layer
    @ViewBuilder
    private func singleLayerView(_ layer: LayerInfo) -> some View {
        Image(systemName: layer.icon)
            .font(.system(size: size * 0.5, weight: .medium))
            .foregroundColor(.white)
    }

    // MARK: - Two Layers
    @ViewBuilder
    private func twoLayersView() -> some View {
        HStack(spacing: size * 0.05) {
            ForEach(Array(layers.prefix(2).enumerated()), id: \.offset) { index, layer in
                Image(systemName: layer.icon)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundColor(layer.isBackground ? .white.opacity(0.5) : .white)
            }
        }
    }

    // MARK: - Three Layers (삼각형 배치)
    @ViewBuilder
    private func threeLayersView() -> some View {
        ZStack {
            // 상단
            Image(systemName: layers[0].icon)
                .font(.system(size: size * 0.3, weight: .medium))
                .foregroundColor(.white)
                .offset(y: -size * 0.15)

            // 하단 좌
            Image(systemName: layers[1].icon)
                .font(.system(size: size * 0.3, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .offset(x: -size * 0.15, y: size * 0.1)

            // 하단 우 (배경음이면 더 작게)
            Image(systemName: layers[2].icon)
                .font(.system(size: layers[2].isBackground ? size * 0.2 : size * 0.3, weight: .medium))
                .foregroundColor(layers[2].isBackground ? .white.opacity(0.5) : .white.opacity(0.9))
                .offset(x: size * 0.15, y: size * 0.1)
        }
    }

    // MARK: - Multiple Layers (원형 배치)
    @ViewBuilder
    private func multipleLayersView() -> some View {
        ZStack {
            ForEach(Array(layers.prefix(5).enumerated()), id: \.offset) { index, layer in
                let angle = (Double(index) / Double(min(layers.count, 5))) * 360.0
                let radius = size * 0.25

                Image(systemName: layer.icon)
                    .font(.system(size: size * 0.25, weight: .medium))
                    .foregroundColor(layer.isBackground ? .white.opacity(0.5) : .white.opacity(0.85))
                    .offset(
                        x: cos(angle * .pi / 180) * radius,
                        y: sin(angle * .pi / 180) * radius
                    )
            }

            // 중앙에 레이어 개수 표시
            if layers.count > 3 {
                Text("\(layers.count)")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Gradient Colors
    private var gradientColors: [Color] {
        let primaryColors = layers
            .filter { !$0.isBackground }
            .map { $0.color }

        if primaryColors.isEmpty {
            return [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]
        } else if primaryColors.count == 1 {
            return [primaryColors[0].opacity(0.7), primaryColors[0].opacity(0.5)]
        } else {
            return primaryColors.map { $0.opacity(0.6) }
        }
    }

    // MARK: - Helper Methods
    private func iconForFilter(_ filter: AudioFilter) -> String {
        switch filter {
        case .WaterDrop: return "drop.fill"
        case .Basement: return "building.fill"
        case .Cave: return "moon.fill"
        case .Pipe: return "cylinder.fill"
        case .Sink: return "rectangle.fill"
        case .SingingBowl: return "circle.circle"
        case .Focus: return "scope"
        case .Training: return "figure.mind.and.body"
        case .Empty: return "circle.dashed"
        case .Vibration: return "waveform"
        case .TibetanBowl: return "circle.hexagongrid.fill"
        case .Bell: return "bell.fill"
        case .BowlDeep: return "circle.circle.fill"
        case .BowlLoud: return "speaker.wave.3.fill"
        case .Bird: return "bird.fill"
        case .Owl: return "moon.stars.fill"
        case .Woodpecker: return "leaf.fill"
        case .Forest: return "tree.fill"
        case .Cuckoo: return "sun.max.fill"
        case .Jungle: return "leaf.arrow.triangle.circlepath"
        case .ForestBird: return "bird"
        case .SpringForest: return "sun.haze.fill"
        case .SoftRain: return "cloud.drizzle.fill"
        case .CityRain: return "cloud.rain.fill"
        case .RainMaker: return "cloud.heavyrain.fill"
        case .AmbientKeys: return "pianokeys"
        case .Underwater: return "water.waves"
        case .MeditationPad: return "sparkles"
        case .Atmosphere: return "waveform.path"
        case .IndigoMusic: return "music.note"
        case .Keyboard: return "keyboard.fill"
        case .Camera: return "camera.fill"
        case .AirShimmer: return "sparkles"
        case .SparkleBells: return "sparkle"
        case .none: return "questionmark"
        }
    }

    private func colorForCategory(_ category: SoundCategory) -> Color {
        switch category {
        case .WaterDrop: return .blue
        case .SingingBowl: return .purple
        case .Bird: return .green
        case .Rain: return .cyan
        case .Ambient: return .indigo
        case .ASMR: return .pink
        case .none: return .gray
        }
    }

    struct LayerInfo {
        let icon: String
        let color: Color
        var isBackground: Bool = false
    }
}

// MARK: - Previews
struct SoundThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 단일 레이어
            SoundThumbnailView(
                sound: CustomSound(
                    title: "물방울",
                    category: .WaterDrop,
                    filter: .WaterDrop
                ),
                size: 80
            )

            // 2개 레이어
            SoundThumbnailView(
                sound: CustomSound(
                    title: "물방울 + 싱잉볼",
                    category: .WaterDrop,
                    filter: .WaterDrop,
                    soundLayers: [
                        CustomSound.SoundLayer(category: .WaterDrop, filter: .WaterDrop),
                        CustomSound.SoundLayer(category: .SingingBowl, filter: .SingingBowl)
                    ]
                ),
                size: 80
            )

            // 3개 레이어 + 배경음
            SoundThumbnailView(
                sound: CustomSound(
                    title: "물방울 + 싱잉볼 + 새",
                    category: .WaterDrop,
                    filter: .WaterDrop,
                    backgroundSound: "피아노",
                    soundLayers: [
                        CustomSound.SoundLayer(category: .WaterDrop, filter: .WaterDrop),
                        CustomSound.SoundLayer(category: .SingingBowl, filter: .SingingBowl),
                        CustomSound.SoundLayer(category: .Bird, filter: .Bird)
                    ]
                ),
                size: 80
            )
        }
        .padding()
        .background(Color.black)
    }
}
