//
//  Haptics.swift
//  Dalbit
//
//  가벼운 촉각 피드백 모음. 세기별로 이름을 붙여 호출부에서 의도가 드러나게 한다.
//

import UIKit

enum Haptics {
    static func soft()      { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func light()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success()   { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
