//
//  LaunchSafety.swift
//  Dalbit
//
//  켤 때마다 같은 자리에서 죽는 일을 알아채고, 다음 실행을 **세이프 모드**로 연다.
//
//  세이프 모드에서 하는 일: 홈의 달을 3D(RealityKit) 대신 예전 2D 로 그린다.
//  3D 달은 이 앱에서 시작과 함께 가장 무거운 일(Metal·텍스처)을 하고, 기기·OS 조합에 따라
//  거기서 죽으면 사용자는 앱을 다시 설치하기 전까지 소리를 하나도 못 듣는다. 2D 로 열면
//  소리는 들을 수 있고, 그동안 크래시 진단(LeeoDiagnostics)이 원인을 보내 온다.
//  세이프 모드로 무사히 뜨면 그다음 실행은 평소대로 3D 로 연다(LeeoCrashLoopGuard 규칙).
//
//  ⚠️ 성공 표시는 홈이 뜨고 몇 초 살아 있은 뒤에 한다. 사람이 앱을 내린 것은 LeeoKit(3.26.1~)이 스스로 성공으로 친다.
//     알람·백그라운드 재생으로만 깨어난 실행은 화면을 그리지 않으므로 성공으로 치지 않는다.
//

import Foundation
import LeeoKit

@MainActor
enum LaunchSafety {
    private static let crashGuard = LeeoCrashLoopGuard(name: "app", defaults: .standard)

    /// 이번 실행이 세이프 모드인가. 실행 도중에 바뀌지 않는다.
    private(set) static var isInSafeMode = false

    /// 앱 시작 맨 앞에서 한 번.
    static func begin() {
        isInSafeMode = crashGuard.beginLaunch()
        if isInSafeMode {
            Log.launch.failure("직전 실행이 연달아 끝나지 못했다 — 이번 실행은 세이프 모드(2D 달)로 연다")
        }
    }

    /// 홈 화면이 떴다. 몇 초 더 살아 있으면 무사히 뜬 것으로 친다.
    static func homeAppeared() {
        crashGuard.markLaunchSucceededAfterSurvivalDelay()
    }
}
