//
//  AppDelegate.swift
//  RelaxOn
//
//  Created by 이가은 on 2022/08/30.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase 초기화 (GoogleService-Info.plist 기반)
        FirebaseApp.configure()
        return true
    }
    // NOTE: SwiftUI의 WindowGroup이 Scene을 직접 관리하도록 커스텀 SceneConfiguration 오버라이드를 제거했다.
    // (기존 SceneDelegate는 빈 구현이었고, 이 오버라이드가 iPad에서 전체화면 대신
    //  아이폰 호환(가운데 창) 모드로 렌더되게 만들던 원인이었다.)
}


