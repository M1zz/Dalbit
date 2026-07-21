//
//  FeedbackInboxView.swift
//  Dalbit
//
//  개발자 전용 피드백 인박스 — 구현은 전부 LeeoKit이 제공한다.
//  진입: 설정의 앱 버전을 7번 탭하면 열린다 (숨은 동선, SettingsView).
//
//  ⚠️ 다른 사용자의 레코드를 읽으려면 CloudKit Dashboard에서 admin 역할을 만들어
//  read/write 권한과 본인 userRecordName을 등록해야 한다.
//  실제 구현: LeeoKit/Sources/LeeoKit/Feedback/LeeoFeedbackInboxView.swift
//

import SwiftUI
import LeeoKit

struct FeedbackInboxView: View {
    var body: some View {
        LeeoFeedbackInboxView<DalbitSpec>()
    }
}
