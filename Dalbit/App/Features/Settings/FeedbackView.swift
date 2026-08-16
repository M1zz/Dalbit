//
//  FeedbackView.swift
//  Dalbit
//
//  피드백 화면은 LeeoKit이 통째로 제공한다 — 여기는 유형 구성용 얇은 래퍼만 남긴다.
//  실제 구현: LeeoKit/Sources/LeeoKit/Feedback/ (제출 + 이메일 폴백 + 인박스 + 푸시 구독)
//

import SwiftUI
import LeeoKit

/// 기존 호출부 호환용 별칭 — rawValue는 서버 데이터와 계약이라 유지.
typealias FeedbackType = LeeoFeedbackType

struct FeedbackView: View {
    /// 진입 시 미리 선택할 유형.
    var initialType: FeedbackType = .improvement

    var body: some View {
        LeeoFeedbackView<DalbitSpec>(
            types: [.improvement, .bug, .feature, .other],
            initialType: initialType
        )
    }
}
