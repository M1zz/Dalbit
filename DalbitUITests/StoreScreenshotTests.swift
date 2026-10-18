//
//  StoreScreenshotTests.swift
//  DalbitUITests
//
//  App Store 스크린샷 원본을 언어마다 같은 장면으로 찍는다(docs/screenshots/raw/<언어>/0N-….png).
//  합성은 scripts/make_marketing_screenshots.py 가 한다.
//
//  평소 시험에서는 건너뛴다. 찍을 때만 환경 변수로 켠다:
//    TEST_RUNNER_DALBIT_SHOTS_DIR=<저장 폴더> TEST_RUNNER_DALBIT_SHOTS_LANG=ja \
//    xcodebuild test ... -only-testing:DalbitUITests/StoreScreenshotTests
//  상태 막대는 찍기 전에 `xcrun simctl status_bar <기기> override --time 9:41 ...` 로 맞춘다.
//

import XCTest

final class StoreScreenshotTests: XCTestCase {

    func testCaptureStoreScreens() throws {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["DALBIT_SHOTS_DIR"], !dir.isEmpty else {
            throw XCTSkip("스크린샷을 찍을 때만 돈다 (DALBIT_SHOTS_DIR)")
        }
        let lang = env["DALBIT_SHOTS_LANG"] ?? "ko"
        let region = ["ko": "ko_KR", "en": "en_US", "ja": "ja_JP"][lang] ?? "en_US"
        let out = URL(fileURLWithPath: dir)
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let app = XCUIApplication()
        app.launchArguments += [
            "-uiTesting",
            "-didShowOnboarding", "YES",
            "-didShowGestureCoach", "YES",
            "-didShowSwipeHint", "YES",
            "-whatsNew.lastSeenVersion", "4.1.1",
            "-AppleLanguages", "(\(lang))",
            "-AppleLocale", region
        ]
        app.launch()

        func save(_ name: String) throws {
            let png = XCUIScreen.main.screenshot().pngRepresentation
            try png.write(to: out.appendingPathComponent(name))
            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // 1. 홈 — 달이 굴러 들어와 자리를 잡을 때까지 기다린다.
        let moon = app.descendants(matching: .any)["home.moon"]
        XCTAssertTrue(moon.waitForExistence(timeout: 20))
        sleep(5)
        try save("01-moon.png")

        // 3. 보관함 (아래로 굴리기)
        moon.swipeDown()
        XCTAssertTrue(app.buttons["library.add"].waitForExistence(timeout: 5))
        sleep(2)
        try save("03-library.png")

        // 2. 소리 만들기 — 빗소리 배경 위에 부드러운 빗소리 한 겹, 다듬기 판을 연 상태
        app.buttons["library.add"].tap()
        let rainBackground = app.buttons["studio.bg.rain"]
        XCTAssertTrue(rainBackground.waitForExistence(timeout: 5))
        rainBackground.tap()
        let softRain = app.buttons["studio.effect.SoftRain"]
        XCTAssertTrue(softRain.waitForExistence(timeout: 5))
        sleep(1)
        softRain.tap()
        sleep(2)
        try save("02-studio.png")

        // 보관함 → 홈으로 돌아와 위로 굴리면 타이머
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["library.close"].waitForExistence(timeout: 5))
        app.buttons["library.close"].tap()
        XCTAssertTrue(moon.waitForExistence(timeout: 5))
        sleep(1)
        moon.swipeUp()
        XCTAssertTrue(app.buttons["timer.close"].waitForExistence(timeout: 5))
        sleep(2)
        try save("04-timer.png")

        // 5. 알람 추가 — 평일 아침, 싱잉볼
        app.buttons["segment.alarm"].tap()
        XCTAssertTrue(app.buttons["alarm.add"].waitForExistence(timeout: 5))
        app.buttons["alarm.add"].tap()
        for weekday in 2...6 {
            let day = app.buttons["alarm.day.\(weekday)"]
            XCTAssertTrue(day.waitForExistence(timeout: 5))
            day.tap()
        }
        app.buttons["alarm.sound.SingingBowl.mp3"].tap()
        sleep(1)
        try save("05-alarm.png")
    }
}
