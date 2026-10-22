//
//  Log.swift
//  Dalbit
//
//  통합 로그(os.Logger). `print` 는 배포 빌드에서 어디에도 남지 않아, 사용자 기기에서 소리가 안 나거나
//  저장이 실패해도 원인을 알 길이 없었다. 여기 분류를 쓰면 Console 앱·sysdiagnose 에 남는다.
//
//  ⚠️ 사람이 적은 글(소리 이름 등)과 오류 설명만 싣는다. 기기·계정 식별자는 싣지 않는다.
//

import Foundation
import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.leeo.LullabyRecipe"

    /// 재생 엔진·레이어·믹싱
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    /// 내 소리 저장·불러오기(UserDefaults · 파일)
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    /// 실행 경계 — 크래시 루프 가드·세이프 모드·출시 전 점검
    static let launch = Logger(subsystem: subsystem, category: "Launch")
    /// 구독·코드 사용
    static let store = Logger(subsystem: subsystem, category: "Store")

    /// Instruments ▸ Points of Interest 에 구간으로 보이는 성능 표식.
    /// 무거운 일(10분짜리 배경음 디코딩, 레이어 준비)이 언제 얼마나 걸리는지 실제 기기에서 잰다.
    static let signposter = OSSignposter(subsystem: subsystem, category: .pointsOfInterest)
}

extension Logger {
    /// 실패 — 사용자가 겪는 문제로 이어지는 것.
    func failure(_ message: String) { error("\(message, privacy: .public)") }
    /// 주의 — 폴백으로 넘어갔거나 무시해도 되는 이상.
    func caution(_ message: String) { warning("\(message, privacy: .public)") }
}
