//
//  MainTabView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/09.
//

import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        // 온보딩 제거 — 바로 메인(재생) 화면으로 진입
        NavigationStack {
            ListenListView()
                .environmentObject(appState)
        }
        // 우주 같은 검은 테마로 고정 (디자인 시스템의 다크 색이 대비까지 맞춰 적용됨)
        .preferredColorScheme(.dark)
        // 손쉬운 사용(큰 글씨)을 폭넓게 지원하되, 일부 비스크롤 화면 보호를 위해 상한을 둔다.
        // (홈 등 주요 화면은 자체적으로 스크롤 처리되어 어떤 크기에서도 깨지지 않는다.)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState())
    }
}
