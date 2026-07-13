//
//  VariationRangeBar.swift
//  RelaxOn
//
//  Created by Claude on 2025/01/26.
//

import SwiftUI

// MARK: - 변동폭 범위 시각화 바

struct VariationRangeBar: View {
    let baseValue: Float
    let variation: Float
    let range: ClosedRange<Float>
    let color: Color
    let unit: String

    var minValue: Float {
        max(range.lowerBound, baseValue * (1.0 - variation))
    }

    var maxValue: Float {
        min(range.upperBound, baseValue * (1.0 + variation))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 범위 표시 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 전체 범위 배경 (연한 색)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    // 가능한 변동 범위 (진한 색)
                    let minPosition = CGFloat((minValue - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let maxPosition = CGFloat((maxValue - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let width = (maxPosition - minPosition) * geometry.size.width

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.6),
                                    color.opacity(0.4)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width, height: 8)
                        .offset(x: minPosition * geometry.size.width)

                    // 현재 기본값 표시 (동그란 점)
                    let currentPosition = CGFloat((baseValue - range.lowerBound) / (range.upperBound - range.lowerBound))

                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                    }
                    .offset(x: currentPosition * geometry.size.width - 8)
                }
            }
            .frame(height: 20)

            // 범위 라벨
            HStack {
                // 최소값
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.Customize.min.localized)
                        .font(.system(size: 9))
                        .foregroundColor(Color(.Text).opacity(0.5))
                    Text(formatValue(value: minValue))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color.opacity(0.8))
                }

                Spacer()

                // 기본값 (중앙)
                VStack(spacing: 2) {
                    Text(L.Customize.base.localized)
                        .font(.system(size: 9))
                        .foregroundColor(Color(.Text).opacity(0.5))
                    Text(formatValue(value: baseValue))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                }

                Spacer()

                // 최대값
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L.Customize.max.localized)
                        .font(.system(size: 9))
                        .foregroundColor(Color(.Text).opacity(0.5))
                    Text(formatValue(value: maxValue))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color.opacity(0.8))
                }
            }

            // 변동 설명
            if variation > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10))
                        .foregroundColor(color.opacity(0.7))

                    Text(variationDescription)
                        .font(.system(size: 10))
                        .foregroundColor(Color(.Text).opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 4)
    }

    func formatValue(value: Float) -> String {
        let secondsUnit = L.Customize.seconds.localized
        if unit == secondsUnit {
            return String(format: "%.1f%@", value, unit)
        } else if unit == "%" {
            return String(format: "%.0f%@", value * 100, unit)
        } else if unit.isEmpty {
            return String(format: "%+.1f", value)
        } else {
            return String(format: "%.1f%@", value, unit)
        }
    }

    var variationDescription: String {
        let percentage = Int(variation * 100)
        let difference = maxValue - minValue
        let secondsUnit = L.Customize.seconds.localized

        if unit == secondsUnit {
            return L.Customize.variationDescriptionSeconds.localized
                .replacingOccurrences(of: "{percentage}", with: "\(percentage)")
                .replacingOccurrences(of: "{difference}", with: String(format: "%.1f", difference))
        } else if unit == "%" {
            let volDiff = difference * 100
            return L.Customize.variationDescriptionPercent.localized
                .replacingOccurrences(of: "{percentage}", with: "\(percentage)")
                .replacingOccurrences(of: "{difference}", with: String(format: "%.0f", volDiff))
        } else {
            return L.Customize.variationDescription.localized
                .replacingOccurrences(of: "{percentage}", with: "\(percentage)")
                .replacingOccurrences(of: "{difference}", with: String(format: "%.1f", difference))
        }
    }
}

// MARK: - 간단한 인디케이터 (5단계 바)

struct VariationIndicator: View {
    let value: Float
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { index in
                let threshold = Float(index) * 0.1
                let isActive = value >= threshold

                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? color : Color.gray.opacity(0.2))
                    .frame(width: 4, height: CGFloat(8 + index * 3))
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
        }
    }
}

// MARK: - Preview

struct VariationRangeBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // 간격 예시
            VariationRangeBar(
                baseValue: 1.0,
                variation: 0.3,
                range: 0.1...2.0,
                color: .blue,
                unit: L.Customize.seconds.localized
            )

            // 볼륨 예시
            VariationRangeBar(
                baseValue: 0.5,
                variation: 0.4,
                range: 0.1...1.0,
                color: .green,
                unit: "%"
            )

            // 피치 예시
            VariationRangeBar(
                baseValue: 0.0,
                variation: 0.25,
                range: -5.0...5.0,
                color: .orange,
                unit: ""
            )

            // 인디케이터 예시
            HStack(spacing: 20) {
                VariationIndicator(value: 0.0, color: .blue)
                VariationIndicator(value: 0.15, color: .green)
                VariationIndicator(value: 0.30, color: .orange)
                VariationIndicator(value: 0.50, color: .red)
            }
        }
        .padding()
        .background(Color(.DefaultBackground))
    }
}
