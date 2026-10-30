//
//  DalbitApp.swift
//  Dalbit
//
//  Created by hyunho lee on 2022/05/22.
//

import SwiftUI
import TipKit
import LeeoKit

@main
struct DalbitApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    @StateObject private var viewModel = CustomSoundViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()

    init() {
        // 크래시 루프 가드 — 직전 실행들이 연달아 죽었으면 이번엔 세이프 모드(2D 달)로 연다.
        // 무엇보다 먼저 판단해야 화면이 그려지기 전에 무거운 경로를 피할 수 있다.
        LaunchSafety.begin()

        #if DEBUG
        // 출시 전 점검 — 계약(DalbitSpec)이 출시할 수 없는 상태면 개발 중에 바로 알아챈다.
        // (부트스트랩을 쓰지 않고 각 장치를 손으로 켜는 앱이라 감사도 여기서 직접 부른다.)
        Self.auditContract()
        #endif

        // UI 시험은 팁 말풍선이 화면을 가리지 않은 상태에서 흐름을 확인한다.
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            Tips.hideAllTipsForTesting()
        }

        // TipKit 초기화 (효과음 끄기 안내 등)
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])

        // ⚠️ 청취 세션 원장을 실행 아주 이른 시점에 깨운다 — 지난 실행이 재생 중에 끝났다면
        //    (사람이 잠들면 앱을 끄지 않으므로 흔한 일이다) 여기서 그 세션이 마감된다.
        _ = ListeningTracker.shared

        // 원격 킬스위치를 먼저 새로 받는다 — 이번 실행에 바로 반영되진 않지만(캐시가
        // 채워지는 건 응답 뒤다) 다음 경로부터는 대시보드에서 내린 값이 적용된다.
        UsageReportingService.refreshRemoteFlags()

        // 크래시·멈춤 진단(MetricKit) 구독. 구독만 하고 즉시 반환하므로 런치 비용이 없다.
        // ⚠️ 페이로드는 iOS 가 하루 한 번꼴로 묶어서 준다 — 방금 난 크래시는 바로 안 올라온다.
        LeeoDiagnostics.shared.start(spec: DalbitSpec.self) {
            LeeoRemoteFlags.isEnabled(DalbitFlag.diagnosticsEnabled)
        }

        // 설치 스냅샷 갱신. "사람이 앱을 열었다"는 신호는 여기 두지 않는다 —
        // 알람·백그라운드 오디오로 깨어난 경우에도 이 경로는 돌기 때문이다.
        UsageReportingService.reportProcessStart()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(viewModel)
                .environmentObject(subscriptionManager)
                // 사용량이 쌓이면 "즐겁게 쓰고 계신가요?" → 만족 시 리뷰 / 아쉬움 시 피드백
                .leeoSatisfactionCheck(DalbitSpec.self)
                // 아이폰 듀오: 접힘을 재서 아래로 흘리고, 시트 · 알림창이 접힌 선을 비킨다 (LeeoKit Fold)
                .foldAware()
        }
        .onChange(of: scenePhase) { _, phase in
            // 사람이 실제로 앞으로 가져온 순간만 활동으로 센다(콜드 런치 + 백그라운드 복귀).
            // 실행 횟수는 프로세스당 1회로 UsageReportingService 가 눌러 준다.
            if phase == .active { UsageReportingService.reportForegroundOpen() }
        }
    }

    #if DEBUG
    /// 계약 감사. 오류(출시 불가)는 개발 중 즉시 멈춰 세우고, 경고는 로그로 남긴다.
    /// 같은 감사를 DalbitTests 의 `testContractIsReleasable` 이 시험에서도 지킨다.
    private static func auditContract() {
        let issues = LeeoPreflight.audit(DalbitSpec.self)
        for issue in issues where issue.severity != .info {
            Log.launch.caution("[LeeoPreflight] \(issue.code) — \(issue.message)")
        }
        assert(issues.isReleasable,
               "DalbitSpec 이 출시 전 점검을 통과하지 못했다: \(issues.errors.map(\.code))")
    }
    #endif
}
