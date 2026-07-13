//
//  SettingsView.swift
//  RelaxOn
//
//  Created by Claude on 2025/01/15.
//

import SwiftUI

/**
 설정 View
 타이머와 기타 설정을 포함
 */
struct SettingsView: View {

    @EnvironmentObject var viewModel: CustomSoundViewModel
    @ObservedObject var timerManager = TimerManager(viewModel: CustomSoundViewModel())
    @State private var hours : [Int] = Array(0...23)
    @State private var minutes : [Int] = Array(0...59)
    @State var isShowingSelectorView: Bool = false
    @State var isShowingTimerProgressView: Bool = false
    @State var progress: Double = 1.0

    // 타이머가 실행 중인지 여부 (시작/일시정지 버튼의 접근성 라벨용)
    private var isTimerRunning: Bool {
        isShowingTimerProgressView && (timerManager.textTimer?.isValid ?? false)
    }

    var body: some View {

        ZStack {
            ScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                // 타이틀
                Text("Settings")
                    .foregroundColor(DS.Colors.textPrimary)
                    .font(DS.Font.title())
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.vertical, DS.Spacing.md)

                ScrollView {
                    VStack(spacing: DS.Spacing.xl) {
                        // 타이머 섹션
                        timerSection()

                        // 향후 다른 설정 추가 가능
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                }
            }
            .dsConstrainedWidth()
        }
        .onAppear {
            timerManager.viewModel = viewModel
            timerManager.timerDidFinish = {
                self.isShowingTimerProgressView = false
            }
        }
    }

    @ViewBuilder
    private func timerSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            // 섹션 제목
            HStack {
                Image(systemName: "timer")
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.accent)
                Text(L.Timer.sleepTimer.localized)
                    .font(DS.Font.headline())
                    .foregroundColor(DS.Colors.textPrimary)
            }

            // 타이머 컨텐츠
            VStack(spacing: DS.Spacing.lg) {

                // 타이머 or 프로그레스
                if isShowingTimerProgressView == false {
                    TimePickerView(hours: $hours,
                                   minutes: $minutes,
                                   selectedTimeIndexHours: $timerManager.selectedTimeIndexHours,
                                   selectedTimeIndexMinutes: $timerManager.selectedTimeIndexMinutes)
                } else {
                    TimerProgressView(timerManager: timerManager)
                }

                // 사운드 선택 버튼
                Button {
                    isShowingSelectorView.toggle()
                } label: {
                    selectSoundButton()
                        .cornerRadius(DS.Radius.sm)
                }
                .navigationDestination(isPresented: $isShowingSelectorView) {
                    TimerSoundSelectModalView()
                }

                // 컨트롤 버튼들
                HStack(spacing: DS.Spacing.lg) {
                    // 리셋 버튼
                    Button {
                        timerManager.stopTimer(timerManager: timerManager)
                        isShowingTimerProgressView = false
                    } label: {
                        if isShowingTimerProgressView {
                            Image(TimerButton.reset_activated.rawValue)
                                .resizable()
                                .frame(width: 70, height: 70)
                        } else {
                            Image(TimerButton.reset_deactivated.rawValue)
                                .resizable()
                                .frame(width: 70, height: 70)
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("초기화")

                    Spacer()

                    // 시작/중단 버튼
                    Button {
                        if isShowingTimerProgressView {
                            if let timer = timerManager.textTimer {
                                if timer.isValid {
                                    timerManager.pauseTimer(timerManager: timerManager)
                                }
                            } else {
                                timerManager.resumeTimer(timerManager: timerManager)
                                if let sound = viewModel.selectedSound {
                                    viewModel.play(with: sound)
                                }
                            }
                        } else {
                            if let sound = viewModel.selectedSound {
                                viewModel.play(with: sound)
                            }
                            isShowingTimerProgressView = true
                        }
                    } label: {
                        if isShowingTimerProgressView == false {
                            Image(TimerButton.start_circle.rawValue)
                                .resizable()
                                .frame(width: 70, height: 70)
                        } else {
                            if let timer = timerManager.textTimer {
                                if timer.isValid {
                                    Image(TimerButton.pause_circle.rawValue)
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                }
                            } else {
                                Image(TimerButton.start_circle.rawValue)
                                    .resizable()
                                    .frame(width: 70, height: 70)
                            }
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(isTimerRunning ? L.A11y.pause.localized : L.A11y.play.localized)
                }
                .padding(.top, DS.Spacing.xs)
            }
            .padding(DS.Spacing.lg)
            .background(DS.Colors.surface)
            .cornerRadius(DS.Radius.lg)
            .shadow(color: DS.Shadow.card.color,
                    radius: DS.Shadow.card.radius,
                    y: DS.Shadow.card.y)
        }
    }

    @ViewBuilder
    private func selectSoundButton() -> some View {
        HStack {
            Text(viewModel.selectedSound?.title ?? L.SaveView.selectYourSound.localized)
                .font(DS.Font.body())
                .foregroundColor(DS.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(DS.Colors.textSecondary)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.surfaceSunken)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(CustomSoundViewModel())
    }
}
