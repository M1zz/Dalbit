//
//  SubscriptionView.swift
//  RelaxOn
//
//  Paywall UI for subscription
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // 무료 사용 코드 입력
    @State private var showPromoField = false
    @State private var promoInput = ""
    @State private var promoResult: PromoResult?

    private enum PromoResult {
        case success(expiry: Date)
        case invalid
    }

    // 법적 링크 (App Store 가이드라인 3.1.2 필수)
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyPolicyURL = URL(string: "https://m1zz.github.io/RelaxOn/privacy.html")!

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(DS.Colors.textTertiary)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, DS.Spacing.md)
                    .padding(.top, DS.Spacing.sm)
                    .accessibilityLabel(L.A11y.closeButton.localized)
                }

                ScrollView {
                    VStack(spacing: DS.Spacing.xxl) {
                        // Header
                        headerSection()

                        // Feature comparison
                        featureComparison()

                        // Price & subscribe
                        purchaseSection()

                        // Restore
                        Button(action: {
                            Task {
                                await subscriptionManager.restorePurchases()
                                if subscriptionManager.isPremium {
                                    dismiss()
                                }
                            }
                        }) {
                            Text(L.Subscription.restore.localized)
                                .font(DS.Font.subhead())
                                .foregroundColor(DS.Colors.textSecondary)
                                .underline()
                        }

                        // 무료 사용 코드 입력
                        promoCodeSection()

                        // 법적 고지 및 약관/개인정보 링크
                        legalSection()
                            .padding(.bottom, DS.Spacing.xxxl)
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                }
            }
            .dsConstrainedWidth()
        }
        .alert(L.Subscription.error.localized, isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .trackScreen("Subscription")
        .onAppear {
            AnalyticsManager.shared.log(.subscriptionView)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection() -> some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DS.Colors.accentSoft)
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(DS.Colors.accent)
            }

            Text(L.Subscription.title.localized)
                .font(DS.Font.largeTitle().weight(.bold))
                .foregroundColor(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(L.Subscription.description.localized)
                .font(DS.Font.callout())
                .foregroundColor(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DS.Spacing.md)
    }

    // MARK: - Feature Comparison

    @ViewBuilder
    private func featureComparison() -> some View {
        VStack(spacing: DS.Spacing.md) {
            // Free tier
            tierCard(
                title: L.Subscription.freeTier.localized,
                icon: "person.fill",
                color: DS.Colors.textSecondary,
                features: [
                    (L.Subscription.freeSoundsLimit.localized, true),
                    (L.Subscription.freeCategoriesLimit.localized, true),
                    (L.Subscription.unlimitedSounds.localized, false),
                    (L.Subscription.allCategories.localized, false)
                ]
            )

            // Premium tier
            tierCard(
                title: L.Subscription.premiumTier.localized,
                icon: "crown.fill",
                color: DS.Colors.accent,
                features: [
                    (L.Subscription.unlimitedSounds.localized, true),
                    (L.Subscription.allCategories.localized, true),
                    (L.Subscription.freeSoundsLimit.localized, true),
                    (L.Subscription.freeCategoriesLimit.localized, true)
                ],
                highlighted: true
            )
        }
    }

    @ViewBuilder
    private func tierCard(
        title: String,
        icon: String,
        color: Color,
        features: [(String, Bool)],
        highlighted: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(title)
                    .font(DS.Font.headline().weight(.bold))
                    .foregroundColor(DS.Colors.textPrimary)
            }

            ForEach(features.indices, id: \.self) { index in
                let feature = features[index]
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: feature.1 ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(feature.1 ? DS.Colors.success : DS.Colors.textTertiary)
                    Text(feature.0)
                        .font(DS.Font.subhead())
                        .foregroundColor(feature.1 ? DS.Colors.textPrimary : DS.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(highlighted ? DS.Colors.accentSoft : DS.Colors.surface)
                .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: 0, y: DS.Shadow.card.y)
                .overlay(
                    highlighted ?
                    RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                        .stroke(DS.Colors.accent, lineWidth: 1.5)
                    : nil
                )
        )
    }

    // MARK: - Purchase Section

    @ViewBuilder
    private func purchaseSection() -> some View {
        VStack(spacing: DS.Spacing.sm) {
            if let product = subscriptionManager.monthlyProduct {
                // Trial info
                if let trial = subscriptionManager.trialText {
                    Text(trial)
                        .font(DS.Font.subhead().weight(.semibold))
                        .foregroundColor(DS.Colors.accent)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.xxs)
                        .background(DS.Colors.accentSoft)
                        .cornerRadius(DS.Radius.sm)
                }

                // Price
                Text(L.Subscription.priceFormat.localized.replacingOccurrences(of: "{price}", with: product.displayPrice))
                    .font(DS.Font.body())
                    .foregroundColor(DS.Colors.textSecondary)

                // Subscribe button
                Button(action: {
                    isPurchasing = true
                    Task {
                        do {
                            try await subscriptionManager.purchase()
                            if subscriptionManager.isPremium {
                                dismiss()
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                        isPurchasing = false
                    }
                }) {
                    HStack(spacing: DS.Spacing.xs) {
                        if isPurchasing {
                            ProgressView()
                                .tint(DS.Colors.onAccent)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                            Text(L.Subscription.subscribe.localized)
                                .font(DS.Font.headline().weight(.bold))
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isPurchasing)
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    ProgressView()
                        .tint(DS.Colors.accent)

                    Text(L.Subscription.loadingProducts.localized)
                        .font(DS.Font.caption())
                        .foregroundColor(DS.Colors.textTertiary)

                    Button(action: {
                        Task {
                            await subscriptionManager.fetchProducts()
                        }
                    }) {
                        Text(L.Subscription.retry.localized)
                            .font(DS.Font.subhead().weight(.medium))
                            .foregroundColor(DS.Colors.accent)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Promo Code Section (무료 사용 코드)

    @ViewBuilder
    private func promoCodeSection() -> some View {
        VStack(spacing: DS.Spacing.sm) {
            if !showPromoField {
                Button(action: {
                    withAnimation { showPromoField = true }
                }) {
                    Text(L.Subscription.promoTitle.localized)
                        .font(DS.Font.subhead())
                        .foregroundColor(DS.Colors.textSecondary)
                        .underline()
                }
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    HStack(spacing: DS.Spacing.xs) {
                        TextField(L.Subscription.promoPlaceholder.localized, text: $promoInput)
                            .textFieldStyle(.plain)
                            .font(DS.Font.body())
                            .foregroundColor(DS.Colors.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                    .fill(DS.Colors.surface)
                            )
                            .onSubmit { redeemPromo() }

                        Button(action: { redeemPromo() }) {
                            Text(L.Subscription.promoApply.localized)
                                .font(DS.Font.subhead().weight(.semibold))
                                .foregroundColor(DS.Colors.onAccent)
                                .padding(.horizontal, DS.Spacing.md)
                                .padding(.vertical, DS.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                        .fill(DS.Colors.accent)
                                )
                        }
                        .disabled(promoInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if let result = promoResult {
                        switch result {
                        case .success(let expiry):
                            Text(String(format: L.Subscription.promoSuccess.localized,
                                        expiry.formatted(date: .abbreviated, time: .omitted)))
                                .font(DS.Font.caption())
                                .foregroundColor(DS.Colors.success)
                                .multilineTextAlignment(.center)
                        case .invalid:
                            Text(L.Subscription.promoInvalid.localized)
                                .font(DS.Font.caption())
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    private func redeemPromo() {
        if subscriptionManager.redeemPromoCode(promoInput) {
            Haptics.soft()
            promoResult = .success(expiry: subscriptionManager.promoExpiryDate ?? Date())
            // 성공 메시지를 잠깐 보여준 뒤 페이월 닫기
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            promoResult = .invalid
        }
    }

    // MARK: - Legal Section

    @ViewBuilder
    private func legalSection() -> some View {
        VStack(spacing: DS.Spacing.sm) {
            // 자동 갱신 안내 문구
            Text(L.Subscription.legalNotice.localized)
                .font(DS.Font.caption())
                .foregroundColor(DS.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // 이용약관(EULA) / 개인정보 처리방침 링크
            HStack(spacing: DS.Spacing.md) {
                Button(action: { openURL(termsOfUseURL) }) {
                    Text(L.Subscription.termsOfUse.localized)
                        .font(DS.Font.caption().weight(.medium))
                        .foregroundColor(DS.Colors.textSecondary)
                        .underline()
                }

                Text("·")
                    .font(DS.Font.caption())
                    .foregroundColor(DS.Colors.textTertiary)

                Button(action: { openURL(privacyPolicyURL) }) {
                    Text(L.Subscription.privacyPolicy.localized)
                        .font(DS.Font.caption().weight(.medium))
                        .foregroundColor(DS.Colors.textSecondary)
                        .underline()
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }
}
