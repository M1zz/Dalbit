//
//  MainTabView.swift
//  Dalbit
//
//  Created by Doyeon on 2023/03/09.
//

import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var appState: AppState

    /// 첫 실행 안내를 봤는지. 설정에서 다시 보기를 누르면 false 로 되돌아온다.
    /// ⚠️ 이 화면(홈을 감싸는 자리)에서 띄운다 — 홈 안쪽에서 띄우면 달의 등장 애니메이션과
    ///    제스처 코치마크가 안내 뒤에서 먼저 돌아가 버려서, 안내를 닫았을 땐 이미 끝나 있다.
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false
    /// 마지막으로 본 '업데이트 소식' 버전. 판단은 `WhatsNewGate.decide` 한 곳에서.
    @AppStorage(WhatsNewContent.lastSeenKey) private var lastSeenWhatsNew = ""
    @State private var showWhatsNew = false

    var body: some View {
        NavigationStack {
            ListenListView()
                .environmentObject(appState)
                // 업데이트 뒤 처음 열 때 한 번. 첫 실행 안내와 다른 뷰에 걸어 두 표지가 겹치지 않게 한다.
                .fullScreenCover(isPresented: $showWhatsNew) {
                    WhatsNewView {
                        lastSeenWhatsNew = WhatsNewContent.version
                        showWhatsNew = false
                    }
                }
        }
        .onAppear(perform: decideWhatsNew)
        .fullScreenCover(isPresented: Binding(get: { !didShowOnboarding },
                                              set: { if !$0 { didShowOnboarding = true } })) {
            OnboardingView { didShowOnboarding = true }
        }
        // 우주 같은 검은 테마로 고정 (디자인 시스템의 다크 색이 대비까지 맞춰 적용됨)
        .preferredColorScheme(.dark)
        // 손쉬운 사용(큰 글씨)을 폭넓게 지원하되, 일부 비스크롤 화면 보호를 위해 상한을 둔다.
        // (홈 등 주요 화면은 자체적으로 스크롤 처리되어 어떤 크기에서도 깨지지 않는다.)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        // 잠시 조작이 없으면 화면이 서서히 어두워지고, 만지면 다시 밝아진다.
        // (설정 > 화면 에서 끌 수 있다)
        .idleDimming()
    }
}

extension MainTabView {
    /// 처음 온 사람은 본 것으로만 적고(첫 실행 안내가 맞이한다), 쓰던 사람에게는 한 번 띄운다.
    private func decideWhatsNew() {
        switch WhatsNewGate.decide(hasCompletedOnboarding: didShowOnboarding,
                                   lastSeenVersion: lastSeenWhatsNew) {
        case .markSeenSilently: lastSeenWhatsNew = WhatsNewContent.version
        case .show: showWhatsNew = true
        case .nothing: break
        }
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState())
    }
}
