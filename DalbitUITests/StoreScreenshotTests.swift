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
        // 언어 하나면 DIR 에 바로, 쉼표로 여럿이면 DIR/<언어>/ 에 차례로 찍는다
        // (언어마다 xcodebuild 를 새로 띄우지 않아 바쁜 Mac 에서 훨씬 빠르다).
        let langs = (env["DALBIT_SHOTS_LANG"] ?? "ko").split(separator: ",").map(String.init)
        for lang in langs {
            let out = langs.count == 1 ? URL(fileURLWithPath: dir)
                                       : URL(fileURLWithPath: dir).appendingPathComponent(lang)
            try capture(lang: lang, out: out)
        }
    }

    private func capture(lang: String, out: URL) throws {
        let region = [
            "ko": "ko_KR", "en": "en_US", "en-GB": "en_GB", "ja": "ja_JP",
            "zh-Hans": "zh_CN", "zh-Hant": "zh_TW", "ru": "ru_RU", "es": "es_ES",
            "de": "de_DE", "fr": "fr_FR", "it": "it_IT", "pt-BR": "pt_BR",
            "th": "th_TH", "vi": "vi_VN", "cs": "cs_CZ", "da": "da_DK",
            "el": "el_GR", "fi": "fi_FI", "id": "id_ID", "nb": "nb_NO",
            "nl": "nl_NL", "pl": "pl_PL", "sv": "sv_SE", "tr": "tr_TR"
        ][lang] ?? "en_US"
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let app = XCUIApplication()
        app.launchArguments += [
            "-uiTesting",
            "-didShowOnboarding", "YES",
            "-didShowGestureCoach", "YES",
            "-didShowSwipeHint", "YES",
            "-whatsNew.lastSeenVersion", "4.1.1",
            // 바쁜 기기에서는 첫 화면까지 45초가 넘어 화면이 저절로 어두워진 채로 찍힌다.
            "-idleDimmingEnabled", "NO",
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

        // 기기가 바쁘면 화면이 아직 미끄러져 들어오는 중이라 눌리지 않는다 — 누를 수 있을 때까지 기다린다.
        func waitReady(_ element: XCUIElement) {
            let ready = expectation(for: NSPredicate(format: "exists == true AND hittable == true"),
                                    evaluatedWith: element)
            wait(for: [ready], timeout: 30)
        }
        // 기기가 바쁘면 쓸어내림이 한 번에 먹지 않을 때가 있다 — 화면이 열릴 때까지 다시 쓸어 본다.
        func swipe(_ gesture: () -> Void, until element: XCUIElement) {
            for _ in 0..<5 {
                gesture()
                if element.waitForExistence(timeout: 8) && element.isHittable { return }
            }
        }
        func tapWhenReady(_ element: XCUIElement) {
            waitReady(element)
            element.tap()
        }

        // 1. 홈 — 달이 굴러 들어와 자리를 잡을 때까지 기다린다.
        let moon = app.descendants(matching: .any)["home.moon"]
        XCTAssertTrue(moon.waitForExistence(timeout: 60))
        sleep(5)
        try save("01-moon.png")

        // 3. 보관함 (아래로 굴리기)
        swipe({ moon.swipeDown() }, until: app.buttons["library.add"])
        XCTAssertTrue(app.buttons["library.add"].waitForExistence(timeout: 30))
        waitReady(app.buttons["library.add"])
        sleep(2)
        try save("03-library.png")

        // 2. 소리 만들기 — 빗소리 배경 위에 부드러운 빗소리 한 겹, 다듬기 판을 연 상태
        tapWhenReady(app.buttons["library.add"])
        let rainBackground = app.buttons["studio.bg.rain"]
        XCTAssertTrue(rainBackground.waitForExistence(timeout: 30))
        let softRain = app.buttons["studio.effect.SoftRain"]
        // 바쁜 기기에서는 배경 누름이 먹지 않을 때가 있다 — 효과음 칸이 열릴 때까지 다시 누른다.
        for _ in 0..<4 where !softRain.exists {
            tapWhenReady(rainBackground)
            if softRain.waitForExistence(timeout: 15) { break }
        }
        XCTAssertTrue(softRain.waitForExistence(timeout: 30))
        sleep(1)
        tapWhenReady(softRain)
        sleep(2)
        try save("02-studio.png")

        // 보관함 → 홈으로 돌아와 위로 굴리면 타이머
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["library.close"].waitForExistence(timeout: 30))
        tapWhenReady(app.buttons["library.close"])
        XCTAssertTrue(moon.waitForExistence(timeout: 30))
        sleep(1)
        swipe({ moon.swipeUp() }, until: app.buttons["timer.close"])
        XCTAssertTrue(app.buttons["timer.close"].waitForExistence(timeout: 30))
        waitReady(app.buttons["timer.close"])
        sleep(2)
        try save("04-timer.png")

        // 5. 알람 추가 — 평일 아침, 싱잉볼
        tapWhenReady(app.buttons["segment.alarm"])
        XCTAssertTrue(app.buttons["alarm.add"].waitForExistence(timeout: 30))
        tapWhenReady(app.buttons["alarm.add"])
        for weekday in 2...6 {
            let day = app.buttons["alarm.day.\(weekday)"]
            XCTAssertTrue(day.waitForExistence(timeout: 30))
            tapWhenReady(day)
        }
        tapWhenReady(app.buttons["alarm.sound.SingingBowl.mp3"])
        sleep(1)
        try save("05-alarm.png")
    }
}
