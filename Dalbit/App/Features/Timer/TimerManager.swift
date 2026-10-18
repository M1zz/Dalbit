//
//  TimerManager.swift
//  Dalbit
//
//  Created by 황석현 on 2023/04/26.
//

import Foundation
import SwiftUI
import OSLog

/**
 Timer의 시간을 감지하는 객체
 */
class TimerManager: ObservableObject {
    
    var viewModel: CustomSoundViewModel?
    var timerDidFinish: (() -> Void)?

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.leeo.LullabyRecipe",
                                    category: "SleepTimer")
    
    @Published var selectedTimeIndexHours: Int = 0
    @Published var selectedTimeIndexMinutes: Int = 15
    @Published var remainingSeconds: Int = 0
    @Published var textTimer: Timer?
    @Published var progressTimer: Timer?
    @Published var progress: Double = 1.0
    
    init(viewModel: CustomSoundViewModel) {
        self.viewModel = viewModel
    }
    
    // 타이머객체 실행
    func startTimer(timerManager: TimerManager) {
        self.remainingSeconds = getTime(timerManager: self)
        didFinishCurrentRun = false
        Self.log.info("수면 타이머 시작: \(self.remainingSeconds / 60, privacy: .public)분")

        AnalyticsManager.shared.log(.timerStart(minutes: self.remainingSeconds / 60))

        // 이미 흐르고 있는 청취 세션에 타이머를 붙인다 — 타이머 화면은 소리가 난 뒤에 열린다.
        ListeningTracker.shared.attachTimer(minutes: self.remainingSeconds / 60)

        // 페이드 인 효과 (3초)
        AudioEngineManager.shared.fadeIn(duration: 3.0)

        self.textTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.remainingSeconds -= 1

            // 타이머 종료 10초 전에 페이드 아웃 시작
            if self.remainingSeconds == 10 {
                AudioEngineManager.shared.fadeOut(duration: 10.0) {
                    // 페이드 아웃 완료 후 실행
                }
            }

            if self.remainingSeconds <= 0 {
                timer.invalidate()
                // 끝까지 끄지 않았다 — 잠들었다고 볼 가장 믿을 만한 신호다.
                self.finishTimer()
            }
        }
    }
    /// 타이머가 끝까지 흘렀다 — 소리를 멈추고, 화면을 못 보는 사람에게도 끝났다고 말한다.
    /// 글자 타이머와 진행바 타이머가 거의 같은 순간에 끝나므로 이미 끝낸 뒤면 아무것도 하지 않는다.
    private var didFinishCurrentRun = false
    private func finishTimer() {
        remainingSeconds = 0
        guard !didFinishCurrentRun else { return }
        didFinishCurrentRun = true
        viewModel?.stopSound(reason: .timerCompleted)
        Self.log.info("수면 타이머 종료 — 소리를 멈춤")
        AccessibilityNotification.Announcement(L.Announce.timerFinished.localized).post()
        timerDidFinish?()
    }

    // 설정한 시간을 초로 변환
    func getTime(timerManager: TimerManager) -> Int {
        var hour = self.selectedTimeIndexHours
        var minute = self.selectedTimeIndexMinutes
        
        hour = hour * 3600
        minute = minute * 60
        
        return hour + minute
    }
    // 타이머 중지
    func stopTimer(timerManager: TimerManager) {
        self.textTimer?.invalidate()
        self.progressTimer?.invalidate()
        self.remainingSeconds = 0
        self.progress = 1.0
        AudioEngineManager.shared.cancelFade()
        // 끝나기 전에 직접 껐다 — 깨어 있었다는 뜻이라 잠든 세션으로 세지 않는다.
        self.viewModel?.stopSound(reason: .timerCancelled)
        AnalyticsManager.shared.log(.timerCancel)
    }
    
    func pauseTimer(timerManager: TimerManager) {
        self.textTimer?.invalidate()
        self.textTimer = nil
        self.progressTimer?.invalidate()
        self.progressTimer = nil
        AudioEngineManager.shared.cancelFade()
        // 일시정지도 사람이 깨어서 손을 댄 것이다.
        self.viewModel?.stopSound(reason: .timerCancelled)
    }
    
    // 타이머 재개
    func resumeTimer(timerManager: TimerManager) {
        // 페이드 인 효과 (재개 시)
        AudioEngineManager.shared.fadeIn(duration: 2.0)

        self.textTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.remainingSeconds -= 1

            // 타이머 종료 10초 전에 페이드 아웃 시작
            if self.remainingSeconds == 10 {
                AudioEngineManager.shared.fadeOut(duration: 10.0) {
                    // 페이드 아웃 완료 후 실행
                }
            }

            if self.remainingSeconds <= 0 {
                timer.invalidate()
                self.finishTimer()
            }
        }
        startTimeprogressBar(timerManager: self)
    }
    
    // 타이머 진행바 실행
    func startTimeprogressBar(timerManager: TimerManager) {
        let settingTime: Double = Double(self.getTime(timerManager: self))
        var secondPercentage: Double = 0
        secondPercentage = Double((1 / settingTime) * 1.0)
        
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.progress -= secondPercentage
            if self.progress <= 0 {
                timer.invalidate()
                self.progress = 1.0
                // 페이드 아웃이 이미 진행 중이므로 여기서는 멈춤만.
                // (텍스트 타이머가 먼저 끝냈으면 finishTimer 가 두 번 말하지 않는다)
                self.finishTimer()
            }
        }
    }
    // 타이머 시간 뷰
    func getTimeText() -> some View {
        if remainingSeconds > 3599 {
            return AnyView (
                Text(String(format: "%02d:%02d:%02d", max(self.remainingSeconds / 3600, 0), max((self.remainingSeconds % 3600) / 60, 0), max(self.remainingSeconds % 60, 0)))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .font(.system(size: 50, weight: .light))
                    .monospacedDigit()
                    // 초가 바뀔 때 숫자만 아래로 굴러간다 — 시계 전체가 깜빡이지 않는다.
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: self.remainingSeconds)
                    .onAppear {
                        if self.remainingSeconds == 0 {
                            self.startTimer(timerManager: self)
                        }
                    }
                    .onDisappear { }
            )
        } else {
            return AnyView (
                Text(String(format: "%02d:%02d", max((self.remainingSeconds % 3600) / 60, 0), max(self.remainingSeconds % 60, 0)))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .font(.system(size: 60, weight: .light))
                    .monospacedDigit()
                    // 초가 바뀔 때 숫자만 아래로 굴러간다 — 시계 전체가 깜빡이지 않는다.
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: self.remainingSeconds)
                    .onAppear {
                        if self.remainingSeconds == 0 {
                            self.startTimer(timerManager: self)
                        }
                    }
                    .onDisappear { }
            )
        }
    }
    // 타이머 원형바 뷰
    func getCircularProgressBar() -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .foregroundColor(DS.Colors.separator)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(DS.Colors.accent)
                .rotationEffect(Angle(degrees: 270.0))
                .onAppear {
                    if self.remainingSeconds == 0 {
                        self.startTimeprogressBar(timerManager: self)
                    }
                }
                .onDisappear { }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}
