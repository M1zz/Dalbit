//
//  UserDefaults+Extension.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/04/18.
//

import Foundation

/**
 UserDefaults에 저장하는 Key 값 Extension
 */
extension UserDefaults {
    struct Keys {
        static let customSound = "CUSTOM_SOUND_KEY"
        static let isFirstVisit = "IS_FIRST"
        static let lastPlayedSoundKey = "LAST_SOUND_KEY"
    }
}
