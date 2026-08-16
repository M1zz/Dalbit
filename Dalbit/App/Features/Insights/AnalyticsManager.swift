//
//  AnalyticsManager.swift
//  Dalbit
//
//  로컬 이벤트 로깅 래퍼 (외부 분석 SDK 미사용).
//  Firebase(Google) Analytics 연동은 제거되었으며, 이벤트는 DEBUG 빌드에서만
//  콘솔에 출력되고 어떤 데이터도 외부로 전송되지 않는다.
//

import Foundation
import SwiftUI

/// 앱에서 추적하는 커스텀 이벤트 정의.
enum AnalyticsEvent {
    case soundPlay(title: String, isLayered: Bool)
    case soundStop
    case soundSave(layerCount: Int, hasBackground: Bool)
    case soundDelete
    /// 즐겨찾기 토글. 켠 것과 끈 것을 함께 받는다 — 허브로는 켠 것만 올라간다.
    case favoriteToggle(isOn: Bool)
    case timerStart(minutes: Int)
    case timerCancel
    case subscriptionView
    case subscriptionPurchase(productId: String)
    case promoRedeem

    var name: String {
        switch self {
        case .soundPlay: return "sound_play"
        case .soundStop: return "sound_stop"
        case .soundSave: return "sound_save"
        case .soundDelete: return "sound_delete"
        case .favoriteToggle: return "favorite_toggle"
        case .timerStart: return "timer_start"
        case .timerCancel: return "timer_cancel"
        case .subscriptionView: return "subscription_view"
        case .subscriptionPurchase: return "subscription_purchase"
        case .promoRedeem: return "promo_redeem"
        }
    }

    /// 공용 허브(FeedbackHub)로 올릴 이벤트 이름. nil 이면 로컬 로그로만 남는다.
    ///
    /// ⚠️ 여기 이름은 **집계용 고정 문자열**이다 — 파라미터(소리 제목 등)는 절대 따라가지 않는다.
    ///    무엇을 왜 보내는지는 UsageReportingService 머리말 참고.
    /// ⚠️ 재생/정지는 여기 없다. 세션의 효용은 길이와 종료 이유로 갈리는데 그건 시작 시점에
    ///    알 수 없어서, 청취는 ListeningTracker 가 세션을 닫을 때 따로 보고한다.
    var hubEvent: String? {
        switch self {
        case .soundSave: return UsageReportingService.mixCreateEvent
        case .timerStart: return UsageReportingService.timerStartEvent
        case .subscriptionView: return UsageReportingService.paywallViewEvent
        case .subscriptionPurchase, .promoRedeem: return UsageReportingService.paywallPurchaseEvent
        // 해제는 올리지 않는다 — "다시 듣고 싶은 소리를 찾았다"는 신호가 있는 건 켠 쪽뿐이다.
        case let .favoriteToggle(isOn): return isOn ? UsageReportingService.favoriteAddEvent : nil
        case .soundPlay, .soundStop, .soundDelete, .timerCancel: return nil
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .soundPlay(title, isLayered):
            return ["sound_title": title, "is_layered": isLayered]
        case let .soundSave(layerCount, hasBackground):
            return ["layer_count": layerCount, "has_background": hasBackground]
        case let .timerStart(minutes):
            return ["minutes": minutes]
        case let .subscriptionPurchase(productId):
            return ["product_id": productId]
        case let .favoriteToggle(isOn):
            return ["is_on": isOn]
        case .soundStop, .soundDelete, .timerCancel, .subscriptionView, .promoRedeem:
            return nil
        }
    }
}

/// 이벤트 로깅 싱글톤.
/// 상세 파라미터는 DEBUG 콘솔에만 남고, 집계가 필요한 일부 이름만 익명 허브로 올라간다.
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    /// 커스텀 이벤트 로깅.
    /// - 콘솔: DEBUG 빌드에서만, 파라미터까지 전부.
    /// - 허브: `hubEvent` 가 있는 이벤트만 **이름만** (쓰로틀은 UsageReportingService 담당).
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        print("📊 [Analytics] \(event.name) \(event.parameters ?? [:])")
        #endif

        if let hubEvent = event.hubEvent {
            UsageReportingService.record(event: hubEvent)
        }
    }

    /// 화면 조회 로깅 (DEBUG 빌드에서만 콘솔 출력)
    func logScreen(_ screenName: String, screenClass: String? = nil) {
        #if DEBUG
        print("📊 [Analytics] screen_view \(screenName)")
        #endif
    }

    /// 사용자 속성 설정 (DEBUG 빌드에서만 콘솔 출력)
    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("📊 [Analytics] userProperty \(name)=\(value ?? "nil")")
        #endif
    }
}

// MARK: - SwiftUI 화면 추적

private struct ScreenTrackingModifier: ViewModifier {
    let screenName: String

    func body(content: Content) -> some View {
        content.onAppear {
            AnalyticsManager.shared.logScreen(screenName)
        }
    }
}

extension View {
    /// 화면이 나타날 때 screen_view 이벤트를 로깅한다.
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTrackingModifier(screenName: name))
    }
}
