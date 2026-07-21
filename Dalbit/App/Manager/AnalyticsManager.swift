//
//  AnalyticsManager.swift
//  RelaxOn
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
        case .timerStart: return "timer_start"
        case .timerCancel: return "timer_cancel"
        case .subscriptionView: return "subscription_view"
        case .subscriptionPurchase: return "subscription_purchase"
        case .promoRedeem: return "promo_redeem"
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
        case .soundStop, .soundDelete, .timerCancel, .subscriptionView, .promoRedeem:
            return nil
        }
    }
}

/// 로컬 전용 이벤트 로깅 싱글톤 (no-op, 외부 전송 없음).
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    /// 커스텀 이벤트 로깅 (DEBUG 빌드에서만 콘솔 출력)
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        print("📊 [Analytics] \(event.name) \(event.parameters ?? [:])")
        #endif
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
