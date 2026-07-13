//
//  SubscriptionManager.swift
//  RelaxOn
//
//  StoreKit 2 subscription manager
//

import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {

    static let productId = "month"
    static let freeMaxCustomSounds = 3
    /// 무료 사용 코드 (고정) — 리딤하면 1개월간 프리미엄
    static let promoCode = "DALBIT-MOON"
    private static let promoExpiryKey = "promoExpiryDate"
    // 무료로 개방된 사운드 카테고리 (6개 중 5개 — ASMR만 프리미엄)
    static let freeCategories: Set<SoundCategory> = [.WaterDrop, .SingingBowl, .Bird, .Rain, .Ambient]

    @Published var isPremium: Bool = false
    @Published var products: [Product] = []

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        #if DEBUG
        // 개발(DEBUG) 빌드에서는 결제 없이 프리미엄 사용 — App Store/TestFlight 빌드는 정상 과금
        isPremium = true
        #endif
        if hasActivePromo {
            isPremium = true
        }
        Task {
            await fetchProducts()
            await checkEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Fetch Products

    func fetchProducts() async {
        do {
            products = try await Product.products(for: [Self.productId])
        } catch {
            print("[SubscriptionManager] Failed to fetch products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product = products.first else { return }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPremium = true
            AnalyticsManager.shared.log(.subscriptionPurchase(productId: product.id))
            AnalyticsManager.shared.setUserProperty("true", forName: "is_premium")

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.productId {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = hasActivePromo
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        #if DEBUG
        // 개발 빌드: 항상 프리미엄 (실제 영수증 검사 건너뜀)
        isPremium = true
        return
        #else
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.productId {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = hasActivePromo
        #endif
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
        isPremium = true
        AnalyticsManager.shared.log(.promoRedeem)
        return true
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                let transaction: Transaction
                switch result {
                case .verified(let t):
                    transaction = t
                case .unverified:
                    continue
                }
                await MainActor.run {
                    if transaction.productID == SubscriptionManager.productId {
                        self.isPremium = transaction.revocationDate == nil || self.hasActivePromo
                    }
                }
                await transaction.finish()
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

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

enum SubscriptionError: Error {
    case verificationFailed
}
