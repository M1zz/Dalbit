//
//  DalbitRoadmap.swift
//  Dalbit
//
//  **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("4.2.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지). 이 앱의 방식대로 키는 `L.Roadmap` 에,
//       문구는 `Localizable.xcstrings` 의 ko · en 에 둘 다 넣는다.
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension DalbitSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 다음에 만들어요
        .init(id: "a11y.voiceover", status: .building,
              title: L.Roadmap.voiceoverTitle.localized,
              detail: L.Roadmap.voiceoverDetail.localized),
        .init(id: "a11y.largetext", status: .building,
              title: L.Roadmap.largetextTitle.localized,
              detail: L.Roadmap.largetextDetail.localized),
        .init(id: "a11y.contrast", status: .shipped("4.1.1"),
              title: L.Roadmap.contrastTitle.localized,
              detail: L.Roadmap.contrastDetail.localized),
        .init(id: "a11y.motion", status: .shipped("4.1.1"),
              title: L.Roadmap.motionTitle.localized,
              detail: L.Roadmap.motionDetail.localized),
        .init(id: "a11y.keyboard", status: .planned,
              title: L.Roadmap.keyboardTitle.localized,
              detail: L.Roadmap.keyboardDetail.localized),
        .init(id: "lang.more", status: .shipped("4.1.1"),
              title: L.Roadmap.langMoreTitle.localized,
              detail: L.Roadmap.langMoreDetail.localized),
        .init(id: "whatsnew", status: .shipped("4.1.1"),
              title: L.Roadmap.whatsnewTitle.localized,
              detail: L.Roadmap.whatsnewDetail.localized),
        .init(id: "gift", status: .planned,
              title: L.Roadmap.giftTitle.localized,
              detail: L.Roadmap.giftDetail.localized),
        .init(id: "widgets", status: .planned,
              title: L.Roadmap.widgetsTitle.localized,
              detail: L.Roadmap.widgetsDetail.localized),
        .init(id: "shortcuts", status: .planned,
              title: L.Roadmap.shortcutsTitle.localized,
              detail: L.Roadmap.shortcutsDetail.localized),
        .init(id: "sync.icloud", status: .planned,
              title: L.Roadmap.syncTitle.localized,
              detail: L.Roadmap.syncDetail.localized),
        .init(id: "backup", status: .planned,
              title: L.Roadmap.backupTitle.localized,
              detail: L.Roadmap.backupDetail.localized),
        .init(id: "fold", status: .planned,
              title: L.Roadmap.foldTitle.localized,
              detail: L.Roadmap.foldDetail.localized),
        .init(id: "data.delete", status: .planned,
              title: L.Roadmap.dataDeleteTitle.localized,
              detail: L.Roadmap.dataDeleteDetail.localized),
        .init(id: "autosave", status: .planned,
              title: L.Roadmap.autosaveTitle.localized,
              detail: L.Roadmap.autosaveDetail.localized),
    ]}
}

// MARK: - 화면

/// 설정 ▸ 앞으로 만들 기능. "이런 기능이 있으면 좋겠어요" 는 기능 제안으로 시작하는 피드백 화면으로 넘어간다
/// (이 앱은 시트 대신 내비게이션으로만 화면을 옮긴다).
struct RoadmapScreen: View {
    @State private var showFeedback = false

    var body: some View {
        LeeoRoadmapView<DalbitSpec>(onSuggest: { showFeedback = true })
            .navigationDestination(isPresented: $showFeedback) {
                FeedbackView(initialType: .feature)
            }
    }
}
