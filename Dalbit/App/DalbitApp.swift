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
    @StateObject private var appState = AppState()
    @StateObject private var viewModel = CustomSoundViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()

    init() {
        // TipKit 초기화 (효과음 끄기 안내 등)
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
        // 리뷰/만족도 프롬프트 타이밍용 실행 기록
        LeeoEngagement.shared.registerLaunch()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(viewModel)
                .environmentObject(subscriptionManager)
                // 사용량이 쌓이면 "즐겁게 쓰고 계신가요?" → 만족 시 리뷰 / 아쉬움 시 피드백
                .leeoSatisfactionCheck(DalbitSpec.self)
        }
    }
}
