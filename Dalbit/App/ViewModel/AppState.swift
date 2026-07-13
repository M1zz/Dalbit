//
//  AppState.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/04/18.
//

import SwiftUI

/**
 탭 아이템을 정의하는 구조체
 */
struct TabItemInfo: Identifiable {
    let id = UUID()
    let view: AnyView
    let imageName: TabBarIcon
    let title: TabItems
}

/// 전역적인 상태를 관리하는 ViewModel
/// SoundSaveView 에서 Modal을 dismiss 한 후 Listen 탭으로 이동하기 위해 필요
final class AppState: ObservableObject {
    @Published var selectedTab: UUID = UUID()
    @Published var showSoundDetail: Bool = false
    
    var tabItems = [
        TabItemInfo(view: AnyView(ListenListView()), imageName: TabBarIcon.listen, title: .listen)
    ]
    
    func moveToTab(_ tab: TabItems) {
        if let tabItem = tabItems.first(where: { $0.title == tab }) {
            selectedTab = tabItem.id
        }
    }
}
