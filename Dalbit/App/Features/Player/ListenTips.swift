//
//  ListenTips.swift
//  Dalbit
//
//  TipKit 안내 — 효과음 끄기, 달 길게 눌러 즐겨찾기.
//

import SwiftUI
import TipKit

/// 효과음(레이어 사운드)이 거슬리면 아래로 스와이프해 보관함에서 끌 수 있다고 안내하는 팁.
/// 앱 실행 초반 최대 3회까지만 노출된다.
struct EffectsOffTip: Tip {
    /// 팁 액션 식별자 (보관함 열기)
    static let openLibraryActionID = "open-library"

    var title: Text {
        Text(L.Tip.effectsOffTitle.localized)
    }

    var message: Text? {
        Text(L.Tip.effectsOffMessage.localized)
    }

    var image: Image? {
        Image(systemName: "speaker.slash.fill")
    }

    var actions: [Action] {
        Action(id: Self.openLibraryActionID, title: L.Tip.openLibrary.localized)
    }

    var options: [any TipOption] {
        // 앱 실행 초반 최대 3회 노출
        Tips.MaxDisplayCount(3)
    }
}

/// 달을 지그시(1초) 누르면 지금 듣는 소리가 즐겨찾기에 담긴다고 안내하는 팁.
/// 초보자에게만 가끔 — 최대 3회 노출, 직접 길게 눌러 담으면 더 이상 보이지 않는다.
struct FavoriteLongPressTip: Tip {
    var title: Text {
        Text(L.Tip.favoriteLongPressTitle.localized)
    }

    var message: Text? {
        Text(L.Tip.favoriteLongPressMessage.localized)
    }

    var image: Image? {
        Image(systemName: "heart")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(3)
    }
}

/**
 커스텀 음원 목록이 노출되는 View
 하단 플레이어 바를 통해 음원 재생, 정지 기능
 */
