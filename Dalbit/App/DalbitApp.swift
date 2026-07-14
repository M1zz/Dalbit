//
//  DalbitApp.swift
//  Dalbit
//
//  Created by hyunho lee on 2022/05/22.
//

import SwiftUI
import TipKit

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
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(viewModel)
                .environmentObject(subscriptionManager)
        }
    }
}
