//
//  DalbitUITests.swift
//  DalbitUITests
//
//  실제 앱을 띄워 핵심 흐름을 한 바퀴 돈다: 홈(달) → 아래로 굴려 보관함 → 설정(메일·리뷰 행) → 돌아오기,
//  그리고 위로 굴려 수면 타이머. 화면마다 손쉬운 사용 감사(performAccessibilityAudit)를 건다.
//
//  ⚠️ 첫 실행 안내·업데이트 소식·제스처 안내·팁은 시험을 가리므로 실행 인자로 '이미 봤다'를 넣는다.
//     `-uiTesting` 은 앱이 CloudKit 보고를 건너뛰고(서명 없는 시뮬레이터 빌드 보호) 팁을 숨기는 표식이다.
//

import XCTest

final class DalbitUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-uiTesting",
            "-didShowOnboarding", "YES",
            "-didShowGestureCoach", "YES",
            "-didShowSwipeHint", "YES",
            "-whatsNew.lastSeenVersion", "4.1.1",
            "-AppleLanguages", "(ko)",
            "-AppleLocale", "ko_KR"
        ]
        app.launch()
    }

    /// 홈 → 보관함 → 설정 → 보관함 → 홈 → 타이머. 사용자가 처음 며칠 동안 가장 많이 도는 길이다.
    func testCoreFlow() throws {
        let moon = app.descendants(matching: .any)["home.moon"]
        XCTAssertTrue(moon.waitForExistence(timeout: 15), "홈의 달이 떠야 한다")

        // 아래로 굴리면 보관함
        moon.swipeDown()
        let settings = app.buttons["library.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "보관함 상단의 설정 버튼")

        // 설정 — 개발자에게 메일 · 리뷰 쓰기 행이 있어야 한다
        settings.tap()
        XCTAssertTrue(app.buttons["settings.mail"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.review"].exists)
        try audit()

        // 돌아와서 보관함 닫기 → 홈
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let close = app.buttons["library.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(moon.waitForExistence(timeout: 5))

        // 위로 굴리면 수면 타이머
        moon.swipeUp()
        XCTAssertTrue(app.buttons["timer.close"].waitForExistence(timeout: 5), "타이머 화면")
    }

    /// 홈 화면 손쉬운 사용 감사.
    func testHomeAccessibilityAudit() throws {
        XCTAssertTrue(app.descendants(matching: .any)["home.moon"].waitForExistence(timeout: 15))
        try audit()
    }

    private func audit() throws {
        try app.performAccessibilityAudit(for: Self.auditedTypes) { issue in
            // ⚠️ '부분 지원'만 거른다. 앱은 MainTabView 에서 글자 크기를 손쉬운 사용 3단계(AX3)까지로
            //    일부러 묶어 두었다(비스크롤 화면 보호). 그 위 두 단계(AX4·AX5)에서 더 커지지 않는 것을
            //    감사가 '부분 지원'으로 잡는다. 전부 풀기는 로드맵 'a11y.largetext'(더 큰 글씨까지)의 일이다.
            //    글자 크기를 아예 따르지 않는 것('unsupported')은 거르지 않는다 — 그건 고친다.
            if issue.auditType == .dynamicType, issue.compactDescription.contains("partially") {
                return true
            }
            return false
        }
    }

    /// 감사 항목.
    ///
    /// 빼는 것과 이유:
    /// - `.contrast`: 화면 뒤로 별이 흐르는 우주 배경이라, 감사가 캡처한 순간 별 한 점이 글자 뒤를 지나면
    ///   대비가 낮게 잡힌다(같은 화면을 다시 재면 통과한다). 실제 글자 대비는 DS.Colors 가 4.5:1 이상으로
    ///   잡고, '대비 증가'를 켜면 한 단계 더 진해진다(Theme.swift).
    private static var auditedTypes: XCUIAccessibilityAuditType {
        XCUIAccessibilityAuditType.all.subtracting([.contrast])
    }
}
