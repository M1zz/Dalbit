//
//  SubscriptionManager.swift
//  RelaxOn
//
//  구독(자동 갱신) 관리자 — 파사드
//
//  StoreKit 2 엔진(상품 로드·구매·복원·권한 추적·트랜잭션 리스너·오프라인 캐시)은
//  이제 LeeoKit 의 LeeoStore 가 공용으로 담당한다. 이 파일은 그 위에 이 앱 고유의
//  로직(무료 카테고리/사운드 개수 게이트, 무료 사용 코드(promo), 애널리틱스)만 얹은
//  얇은 파사드로, 기존 호출부·SubscriptionView 는 그대로 동작한다.
//

import Foundation
import Combine
import StoreKit
import LeeoKit

@MainActor
class SubscriptionManager: ObservableObject {

    static let productId = "month"
    static let freeMaxCustomSounds = 3
    /// 무료 사용 코드 (고정) — 리딤하면 1개월간 프리미엄
    static let promoCode = "DALBIT-MOON"
    private static let promoExpiryKey = "promoExpiryDate"
    // 무료로 개방된 사운드 카테고리 (6개 중 5개 — ASMR만 프리미엄)
    static let freeCategories: Set<SoundCategory> = [.WaterDrop, .SingingBowl, .Bird, .Rain, .Ambient]

    /// StoreKit 2 코어. 상품 로드·구매·복원·권한 판정을 공용으로 처리한다.
    private let store: LeeoStore
    private var cancellable: AnyCancellable?

    init() {
        store = LeeoStore(
            config: DalbitSpec.paywall!,
            // 개발(DEBUG) 빌드에서는 결제 없이 프리미엄 사용 — App Store/TestFlight 빌드는 정상 과금.
            unlockOverride: {
                #if DEBUG
                return true
                #else
                return nil
                #endif
            }
        )
        // 공용 스토어의 상태 변화를 그대로 뷰에 전파한다.
        cancellable = store.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }

    // MARK: - 공개 상태 (기존 API 유지)

    /// 프리미엄 여부 = 실제 구독 권한(또는 DEBUG 언락) 이거나 유효한 무료 사용 코드 보유.
    var isPremium: Bool { store.hasPro || hasActivePromo }

    /// 로드된 판매 상품.
    var products: [Product] { store.products }

    // MARK: - Fetch Products

    func fetchProducts() async {
        await store.loadProducts()
    }

    // MARK: - Purchase

    func purchase() async throws {
        let succeeded = await store.purchasePrimary()
        if succeeded {
            let purchasedID = store.products.first?.id ?? Self.productId
            AnalyticsManager.shared.log(.subscriptionPurchase(productId: purchasedID))
            AnalyticsManager.shared.setUserProperty("true", forName: "is_premium")
            return
        }
        // 사용자 취소는 오류가 없다(lastError == nil) → 조용히 반환.
        // 검증 실패/대기 등 오류가 있으면 기존과 동일하게 던져서 페이월이 알림을 띄우게 한다.
        if let message = store.lastError {
            throw SubscriptionError.message(message)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        await store.restore()
        // isPremium 은 store.hasPro 또는 hasActivePromo 로 계산되므로 별도 처리가 필요 없다.
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        await store.refreshEntitlements()
    }

    // MARK: - Promo Code (무료 사용 코드)

    /// 저장된 무료 사용 코드 만료일
    var promoExpiryDate: Date? {
        UserDefaults.standard.object(forKey: Self.promoExpiryKey) as? Date
    }

    /// 무료 사용 코드가 아직 유효한지
    var hasActivePromo: Bool {
        guard let expiry = promoExpiryDate else { return false }
        return expiry > Date()
    }

    /// 무료 사용 코드 리딤 — 성공 시 1개월간 프리미엄
    @discardableResult
    func redeemPromoCode(_ code: String) -> Bool {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized == Self.promoCode else { return false }

        let expiry = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date().addingTimeInterval(30 * 24 * 3600)
        UserDefaults.standard.set(expiry, forKey: Self.promoExpiryKey)
        // isPremium 이 hasActivePromo 를 참조하므로, 뷰가 갱신되도록 변경을 통지한다.
        objectWillChange.send()
        AnalyticsManager.shared.log(.promoRedeem)
        return true
    }

    // MARK: - Helpers

    var monthlyProduct: Product? {
        products.first
    }

    var trialText: String? {
        guard let offer = monthlyProduct?.subscription?.introductoryOffer else { return nil }
        let period = offer.period
        if period.unit == .week && period.value == 1 {
            return L.Subscription.freeTrialWeek.localized
        }
        return nil
    }

    func isCategoryLocked(_ category: SoundCategory) -> Bool {
        if isPremium { return false }
        return !Self.freeCategories.contains(category)
    }

    func canCreateMoreSounds(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < Self.freeMaxCustomSounds
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case message(String)

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return L.Subscription.error.localized
        case .message(let message):
            return message
        }
    }
}
