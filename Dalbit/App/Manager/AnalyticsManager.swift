//
//  AnalyticsManager.swift
//  RelaxOn
//
//  Firebase(Google) Analytics 래퍼.
//  앱 전역에서 이벤트/화면/사용자 속성 로깅을 일관된 API로 처리한다.
//

import Foundation
import SwiftUI
import FirebaseAnalytics

/// 앱에서 추적하는 커스텀 이벤트 정의.
/// Firebase 이벤트 이름은 영문 소문자+언더스코어, 40자 이내 규칙을 따른다.
enum AnalyticsEvent {
    case soundPlay(title: String, isLayered: Bool)
    case soundStop
    case soundSave(layerCount: Int, hasBackground: Bool)
    case soundDelete
    case timerStart(minutes: Int)
    case timerCancel
    case subscriptionView
    case subscriptionPurchase(productId: String)

    var name: String {
        switch self {
        case .soundPlay: return "sound_play"
        case .soundStop: return "sound_stop"
        case .soundSave: return "sound_save"
        case .soundDelete: return "sound_delete"
        case .timerStart: return "timer_start"
        case .timerCancel: return "timer_cancel"
        case .subscriptionView: return "subscription_view"
        case .subscriptionPurchase: return "subscription_purchase"
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
        case .soundStop, .soundDelete, .timerCancel, .subscriptionView:
            return nil
        }
    }
}

/// Firebase Analytics 싱글톤 래퍼.
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    /// 커스텀 이벤트 로깅
    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    /// 화면 조회 로깅 (Firebase 표준 screen_view 이벤트)
    func logScreen(_ screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }

    /// 사용자 속성 설정 (예: 구독 여부)
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
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
    /// 화면이 나타날 때 screen_view 이벤트를 자동 로깅한다.
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTrackingModifier(screenName: name))
    }
}
