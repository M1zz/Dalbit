//
//  SoundIntents.swift
//  Dalbit
//
//  누운 채로 말로 튼다.
//   - "달빛으로 빗소리 틀어줘": 내가 만든 소리나 기본 소리를 이름으로 골라 튼다.
//   - "달빛 꺼줘": 천천히 줄이며 끈다.
//
//  내가 만든 소리는 Spotlight 에 색인해 Siri 가 이름으로 찾게 한다. 기본 소리는 고정 목록이라 색인하지 않는다.
//

import AppIntents
import CoreSpotlight
import Foundation

struct DalbitSoundEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("소리", comment: "Siri: a sleep sound")
    )
    static let defaultQuery = DalbitSoundQuery()

    /// "custom:<UUID>" 또는 "preset:<id>"
    let id: String
    let title: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }

    /// 내가 만든 소리가 먼저, 그다음 기본 소리.
    static func all() -> [DalbitSoundEntity] {
        let custom = UserDefaultsManager.shared.customSounds.map {
            DalbitSoundEntity(id: "custom:\($0.id.uuidString)", title: $0.title)
        }
        let presets = PresetSound.allPresets.map { DalbitSoundEntity(id: "preset:\($0.id)", title: $0.localizedName) }
        return custom + presets
    }

    /// 실제로 틀 소리. 기본 소리는 앱처럼 CustomSound 로 바꿔 튼다.
    func sound() -> CustomSound? {
        if id.hasPrefix("custom:"), let uuid = UUID(uuidString: String(id.dropFirst("custom:".count))) {
            return UserDefaultsManager.shared.customSounds.first { $0.id == uuid }
        }
        if id.hasPrefix("preset:") {
            let presetID = String(id.dropFirst("preset:".count))
            return PresetSound.allPresets.first { $0.id == presetID }?.toCustomSound()
        }
        return nil
    }
}

extension DalbitSoundEntity: IndexedEntity {}

extension DalbitSoundEntity {
    /// 내가 만든 소리만 다시 색인한다. 앱을 열 때 · 뒤로 보낼 때 부른다.
    static func reindex() async {
        let mine = all().filter { $0.id.hasPrefix("custom:") }
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: DalbitSoundEntity.self)
        try? await index.indexAppEntities(mine)
    }
}

struct DalbitSoundQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [DalbitSoundEntity] {
        let wanted = Set(identifiers)
        return DalbitSoundEntity.all().filter { wanted.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [DalbitSoundEntity] {
        DalbitSoundEntity.all().filter { $0.title.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [DalbitSoundEntity] {
        DalbitSoundEntity.all()
    }
}

struct PlaySoundIntent: AppIntent {
    static let title = LocalizedStringResource("소리 틀기", comment: "Siri: play a sleep sound")
    static let description = IntentDescription(
        LocalizedStringResource("고른 소리를 틉니다.", comment: "Siri: play sound description")
    )
    static let openAppWhenRun = true

    @Parameter(title: LocalizedStringResource("소리", comment: "Siri: sound parameter"),
               description: LocalizedStringResource("내가 만든 소리나 기본 소리 중 틀 소리입니다.", comment: "Siri: sound parameter description"),
               requestValueDialog: IntentDialog(LocalizedStringResource("어떤 소리를 틀까요?", comment: "Siri: ask which sound")))
    var sound: DalbitSoundEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        if let playable = sound.sound() { CustomSoundViewModel.shared.play(with: playable) }
        return .result()
    }

    /// 앱에서 저장한 소리를 골라 틀면 Siri 에게 알려 준다. 다음에 Siri 가 이 동작을 더 잘 고른다.
    static func donate(_ sound: CustomSound) {
        var intent = PlaySoundIntent()
        intent.sound = DalbitSoundEntity(id: "custom:\(sound.id.uuidString)", title: sound.title)
        Task { _ = try? await intent.donate() }
    }
}

struct StopSoundIntent: AppIntent {
    static let title = LocalizedStringResource("소리 끄기", comment: "Siri: stop the sleep sound")
    static let description = IntentDescription(
        LocalizedStringResource("천천히 줄이며 끕니다.", comment: "Siri: stop sound description")
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        CustomSoundViewModel.shared.stopSound()
        return .result()
    }
}

struct DalbitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlaySoundIntent(),
            phrases: ["Play \(\.$sound) on \(.applicationName)", "Play a sleep sound on \(.applicationName)"],
            shortTitle: "Play Sound",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StopSoundIntent(),
            phrases: ["Stop \(.applicationName)", "Turn off \(.applicationName)"],
            shortTitle: "Stop Sound",
            systemImageName: "stop.fill"
        )
    }
}
