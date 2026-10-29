//
//  DalbitSpec.swift
//  Dalbit
//
//  LeeoKit 계약(LeeoAppSpec) 준수 — 이 앱의 공통 기능 설정값 단일 소스.
//  피드백 시스템 구현은 전부 LeeoKit에 있고, 앱은 이 설정만 제공한다.
//
//  ⚠️ recordType/구독 ID는 CloudKit Dashboard·기존 사용자 기기와의 계약이다 — 변경 금지.
//  컨테이너는 공용 피드백 허브(FeedbackHub)로 전환됨 — appIdentifier로 앱을 구분한다.
//  (전환 전 자기 컨테이너 iCloud.com.leeo.LullabyRecipe에 쌓인 기존 피드백은 허브 인박스에 나타나지 않는다.)
//

import Foundation
import LeeoKit

enum DalbitSpec: LeeoAppSpec {
    static let appName = "달빛"
    static let developerEmail = "mizzking75@gmail.com"

    /// App Store 앱 ID — '리뷰 쓰기' 가 작성 페이지로 바로 간다.
    /// 확인: `curl "https://itunes.apple.com/lookup?bundleId=com.leeo.LullabyRecipe"`
    static let appStoreID: String? = "1626715109"

    /// 무료 문턱 — 앱에 원래 있던 한도(직접 만든 소리 3개)를 계약으로 선언한다.
    /// 판정은 `SubscriptionManager.canCreateMoreSounds` 가 `LeeoGate` 로 한다(페이월이 뜨는 유일한 문턱).
    enum GateKey {
        static let customSound = "customSound"
    }
    static let gatePolicy = LeeoGatePolicy(freeLimits: [GateKey.customSound: 3])

    /// Dalbit.entitlements에 iCloud.com.Ysoup.FeedbackHub 컨테이너가 있어야 한다.
    /// 공용 피드백 허브(FeedbackHub)로 수집 — appIdentifier로 앱을 구분한다.
    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.leeo.LullabyRecipe"
    )

    /// 개인정보·지원 링크 (LeeoKit 3.x 부터 필수).
    /// ⚠️ 주소는 App Store Connect 에 등록한 것(`APPSTORE.md`)과 같아야 한다.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/Dalbit/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/Dalbit/support.html")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        // 계정을 만들지 않는다 — 데이터는 사용자 기기에만 있다.
        createsAccounts: false
    )

    /// 수익모델 (LeeoKit 3.x 부터 필수) — 무료로 쓰다가 월 구독으로 프리미엄을 연다.
    /// 실제 판매 설정은 아래 `paywall` 이 우선한다(직접 선언). 둘의 상품 ID 는 같아야 한다.
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: [SubscriptionManager.productId],
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            gate: gatePolicy,
            tipJar: tipJar
        )
    )

    /// 개발자 응원하기(팁, 소모성 세 가지 — 작은 것부터). 기능을 열지 않는다.
    /// ⚠️ productIDs · entitlementIDs 에 넣지 않는다. 넣으면 팁을 낸 사람이 프리미엄이 된다.
    static let tipJar = LeeoTipJarConfig(productIDs: [
        "com.leeo.LullabyRecipe.tip.small",
        "com.leeo.LullabyRecipe.tip.medium",
        "com.leeo.LullabyRecipe.tip.large"
    ])

    /// 인앱 결제(구독). StoreKit 엔진은 LeeoKit(LeeoStore)이 담당하고,
    /// 앱은 이 구성과 얇은 SubscriptionManager 파사드(무료 게이트·프로모 코드)만 유지한다.
    /// ⚠️ 상품 ID("month")는 App Store Connect·기존 사용자 기기와의 계약이다 — 변경 금지.
    /// ⚠️ 타입을 반드시 `LeeoPaywallConfig?`로 명시할 것.
    /// non-optional로 두면(`static let paywall = LeeoPaywallConfig(...)`) 이 선언이
    /// 프로토콜의 optional 요구사항(`static var paywall: LeeoPaywallConfig?`)을 witness하지 못해,
    /// Optional 문맥(`DalbitSpec.paywall!`)에서 접근할 때 기본 구현 `{ nil }`에 바인딩되어 크래시한다.
    static let paywall: LeeoPaywallConfig? = LeeoPaywallConfig(
        productIDs: [SubscriptionManager.productId],
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
        privacyURL: URL(string: "https://m1zz.github.io/Dalbit/privacy.html"),
        gate: gatePolicy,
        tipJar: tipJar
    )
}

/// 심사 없이 원격으로 끌 수 있는 기능.
///
/// ⚠️ `rawValue` 는 CloudKit `RemoteFlags` 레코드의 **필드명과 정확히 같아야** 한다.
///    이름이 어긋나면 대시보드에서 아무리 꺼도 앱은 켠 채로 돈다(조용한 실패).
/// ⚠️ 필드를 안 만들어도 된다 — 없으면 "켬"으로 동작하는 게 안전 기본값이다.
enum DalbitFlag: String, LeeoRemoteFlag, CaseIterable {
    /// 익명 사용 통계 수집. 심사 지적·개인정보 문의를 받으면 이 값을 0 으로 내린다.
    case usageReportingEnabled
    /// 크래시·멈춤 진단 수집(MetricKit). 사용 통계와 따로 끌 수 있어야 한다 —
    /// 둘은 App Privacy 신고 항목이 다르고(Usage Data vs CrashData), 문제가 생기는 이유도 다르다.
    case diagnosticsEnabled
}
