//
//  Sound.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/15.
//

import Foundation

protocol Playable {
    var filter: AudioFilter { get set }
    var category: SoundCategory { get }
}

/**
 앱 번들에 있는 원본 사운드를 불러오기 위한 구조체
 */
struct OriginalSound: Equatable, Hashable, Playable {
    let name: String
    var filter: AudioFilter
    let category: SoundCategory
    let color: String
    
    init(name: String, filter: AudioFilter, category: SoundCategory) {
        self.name = name
        self.filter = filter
        self.category = category
        self.color = category.defaultColor
    }
}
