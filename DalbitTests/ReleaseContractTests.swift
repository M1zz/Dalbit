//
//  ReleaseContractTests.swift
//  DalbitTests
//
//  출시를 막아야 하는 것들 — 계약(DalbitSpec) 감사, 무료 문턱, 업데이트 소식을 누구에게 띄우는가.
//
//  ⚠️ 앱도 DEBUG 로 켤 때마다 같은 감사를 돌린다(DalbitApp.auditContract). 여기 시험은
//     앱을 켜지 않고도, CI 에서도 같은 기준을 지키게 한다.
//

import XCTest
import LeeoKit
@testable import Dalbit

final class ReleaseContractTests: XCTestCase {

    // MARK: - 출시 전 점검

    func testContractIsReleasable() {
        let issues = LeeoPreflight.audit(DalbitSpec.self)
        XCTAssertTrue(issues.isReleasable, "출시 불가 항목: \(issues.errors.map(\.code))")
    }

    /// 무료 사용자가 페이월에 닿을 길(무료 문턱)이 계약에 선언돼 있어야 한다 — 없으면 팔 물건만 있고 살 이유가 없다.
    func testFreeGateIsDeclared() {
        let issues = LeeoPreflight.audit(DalbitSpec.self)
        XCTAssertFalse(issues.contains { $0.code == "gate.noPath" })
        XCTAssertEqual(DalbitSpec.monetization.gate, DalbitSpec.gatePolicy)
        XCTAssertEqual(DalbitSpec.paywall?.gate, DalbitSpec.gatePolicy)
    }

    func testLegalLinksPointToPagesThatExist() {
        // App Store 에 등록한 지원 URL 과 같아야 한다(APPSTORE.md · docs/support.html).
        XCTAssertEqual(DalbitSpec.legal.supportURL.absoluteString, "https://m1zz.github.io/Dalbit/support.html")
        XCTAssertEqual(DalbitSpec.legal.privacyURL.scheme, "https")
        XCTAssertNotNil(DalbitSpec.appStoreID)
    }

    // MARK: - 무료 문턱 (내가 만든 소리 3개)

    func testFreeUserCanCreateUpToThreeSounds() {
        let gate = LeeoGate(policy: DalbitSpec.gatePolicy, hasPro: false, isTrialActive: false)
        let key = DalbitSpec.GateKey.customSound
        XCTAssertTrue(gate.evaluate(key, current: 0).isAllowed)
        XCTAssertTrue(gate.evaluate(key, current: 2).isAllowed)
        guard case .blocked(let reason) = gate.evaluate(key, current: 3) else {
            return XCTFail("4번째 소리는 페이월로 가야 한다")
        }
        XCTAssertEqual(reason.kind, .limitReached(limit: 3))
    }

    func testPremiumIsNeverBlocked() {
        let gate = LeeoGate(policy: DalbitSpec.gatePolicy, hasPro: true, isTrialActive: false)
        XCTAssertTrue(gate.evaluate(DalbitSpec.GateKey.customSound, current: 50).isAllowed)
    }

    @MainActor
    func testFreeLimitMatchesWhatTheLibraryCounterShows() {
        XCTAssertEqual(SubscriptionManager.freeMaxCustomSounds, 3)
    }

    // MARK: - 업데이트 소식

    func testNewcomerNeverSeesWhatsNewButIsMarked() {
        XCTAssertEqual(WhatsNewGate.decide(hasCompletedOnboarding: false, lastSeenVersion: ""),
                       .markSeenSilently)
    }

    func testReturningUserSeesWhatsNewOnce() {
        XCTAssertEqual(WhatsNewGate.decide(hasCompletedOnboarding: true, lastSeenVersion: "4.1.0",
                                           currentVersion: "4.1.1"), .show)
        XCTAssertEqual(WhatsNewGate.decide(hasCompletedOnboarding: true, lastSeenVersion: "4.1.1",
                                           currentVersion: "4.1.1"), .nothing)
    }

    func testWhatsNewItemsAreTranslatedInEveryLanguage() {
        let bundle = Bundle(for: CustomSoundViewModel.self)
        for lang in ["ko", "en", "ja"] {
            guard let path = bundle.path(forResource: lang, ofType: "lproj"),
                  let lproj = Bundle(path: path) else {
                return XCTFail("\(lang).lproj 가 번들에 없다")
            }
            for item in WhatsNewContent.items {
                for key in [item.titleKey, item.detailKey] {
                    let value = lproj.localizedString(forKey: key, value: "⛔️", table: nil)
                    XCTAssertNotEqual(value, "⛔️", "\(lang): \(key) 번역 없음")
                    XCTAssertNotEqual(value, key, "\(lang): \(key) 번역 없음")
                }
            }
        }
    }

    // MARK: - 지역 맞춤 표기

    func testAlarmTimeFollowsLocaleClock() {
        let alarm = AlarmItem(hour: 7, minute: 5)
        XCTAssertTrue(alarm.timeText.contains("05"), "분은 두 자리: \(alarm.timeText)")
        XCTAssertTrue(alarm.timeText.contains("7"), alarm.timeText)
    }
}
