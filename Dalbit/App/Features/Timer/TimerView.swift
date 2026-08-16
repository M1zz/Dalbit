//
//  TimerView.swift
//  Dalbit
//
//  수면 타이머 — 달에서 위로 스와이프하면 나오는 화면. 시간 선택과 진행 표시.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @ObservedObject var timerManager: TimerManager
    @Binding var isShowingTimer: Bool
    @State private var hours: [Int] = Array(0...23)
    @State private var minutes: [Int] = Array(0...59)
    @State private var isTimerRunning = false

    var body: some View {
        ZStack {
            // 배경 없음(투명) — 상위의 공유 우주 별 배경(Starfield·CosmicEvents)이 비치도록 한다.
            VStack(spacing: 0) {
                if isTimerRunning {
                    // 타이머 실행 중
                    timerProgressView()
                } else {
                    // 타이머 설정
                    timerSettingView()
                }
            }
            .dsConstrainedWidth()
        }
        .navigationTitle(L.Timer.sleepTimer.localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isTimerRunning = timerManager.textTimer != nil && timerManager.remainingSeconds > 0
        }
    }

    // 남은 시간을 VoiceOver용 문자열로 변환
    private func formatRemainingTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return "\(hours)\(L.Timer.hour.localized) \(minutes)\(L.Timer.minute.localized)"
        } else if minutes > 0 {
            return "\(minutes)\(L.Timer.minute.localized) \(secs)\(L.Timer.second.localized)"
        } else {
            return "\(secs)\(L.Timer.second.localized)"
        }
    }

    // MARK: - Timer Setting View
    @ViewBuilder
    private func timerSettingView() -> some View {
        VStack(spacing: DS.Spacing.xxl) {
            Spacer()

            // 표식 — 채운 원판 + SF Symbol 대신 빛으로만 그린 초승달.
            // 배경의 별이 그대로 비쳐서 홈의 우주와 끊기지 않는다(CrescentGlyph 주석 참고).
            CrescentGlyph(size: 116)

            VStack(spacing: DS.Spacing.xs) {
                Text(L.Timer.forGoodSleep.localized)
                    .font(DS.Font.title())
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(L.Timer.autoStopDescription.localized)
                    .font(DS.Font.callout())
                    .foregroundColor(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            // 시간 선택
            TimePickerView(
                hours: $hours,
                minutes: $minutes,
                selectedTimeIndexHours: $timerManager.selectedTimeIndexHours,
                selectedTimeIndexMinutes: $timerManager.selectedTimeIndexMinutes
            )

            Spacer()

            // 시작 버튼
            Button {
                if let sound = viewModel.selectedSound {
                    viewModel.play(with: sound)
                }
                timerManager.startTimer(timerManager: timerManager)
                withAnimation {
                    isTimerRunning = true
                }
            } label: {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "play.fill")
                    Text(L.Timer.startTimer.localized)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.xxl)
        }
    }

    // MARK: - Timer Progress View
    @ViewBuilder
    private func timerProgressView() -> some View {
        VStack(spacing: 40) {
            Spacer()

            // 원형 프로그레스 바
            ZStack {
                timerManager.getCircularProgressBar()
                    .frame(width: 280, height: 280)
                    .accessibilityHidden(true)

                VStack(spacing: DS.Spacing.xs) {
                    timerManager.getTimeText()
                        .foregroundColor(DS.Colors.textPrimary)

                    Text(L.Timer.remainingTime.localized)
                        .font(DS.Font.callout())
                        .foregroundColor(DS.Colors.textSecondary)
                }
                // 남은 시간을 하나의 요소로 묶고, 값이 바뀔 때마다 VoiceOver가 갱신
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L.A11y.remainingTimeLabel.localized)
                .accessibilityValue(formatRemainingTime(timerManager.remainingSeconds))
                .accessibilityAddTraits(.updatesFrequently)
            }

            Spacer()

            // 컨트롤 버튼들
            HStack(spacing: 20) {
                // 중지 버튼
                Button(action: {
                    timerManager.stopTimer(timerManager: timerManager)
                    withAnimation {
                        isTimerRunning = false
                    }
                }) {
                    VStack(spacing: DS.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(DS.Colors.surfaceSunken)
                                .frame(width: 70, height: 70)

                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                                .foregroundColor(DS.Colors.textSecondary)
                        }

                        Text(L.Timer.stop.localized)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L.Timer.stop.localized)

                Spacer()

                // 일시정지/재개 버튼
                Button(action: {
                    if let timer = timerManager.textTimer, timer.isValid {
                        timerManager.pauseTimer(timerManager: timerManager)
                    } else {
                        timerManager.resumeTimer(timerManager: timerManager)
                        if let sound = viewModel.selectedSound {
                            viewModel.play(with: sound)
                        }
                    }
                }) {
                    VStack(spacing: DS.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(DS.Colors.accent)
                                .frame(width: 90, height: 90)
                                .shadow(color: DS.Colors.accent.opacity(0.4), radius: 16, x: 0, y: 8)

                            Image(systemName: timerManager.textTimer?.isValid == true ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }

                        Text(timerManager.textTimer?.isValid == true ? L.Timer.pause.localized : L.Timer.resume.localized)
                            .font(DS.Font.caption())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(timerManager.textTimer?.isValid == true ? L.Timer.pause.localized : L.Timer.resume.localized)
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 60)
        }
    }
}
