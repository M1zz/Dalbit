//
//  DalbitApp.swift
//  Dalbit
//
//  Created by hyunho lee on 2022/05/22.
//

import SwiftUI

@main
struct DalbitApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    @StateObject private var appState = AppState()
    @StateObject private var viewModel = CustomSoundViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(viewModel)
                .environmentObject(subscriptionManager)
        }
    }
}
