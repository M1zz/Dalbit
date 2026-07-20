//
//  UserDefaultsManager.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/27.
//

import Foundation

/**
 UserDefaults에 사용자가 저장한 사운드 정보 & 온보딩 여부 & 마지막 재생 사운드 정보
 */
final class UserDefaultsManager {
    
    // MARK: - Properties
    static let shared = UserDefaultsManager()
    private let standard = UserDefaults.standard
    private let CUSTOM_SOUND_KEY = UserDefaults.Keys.customSound
    private let IS_FIRST_VISIT = UserDefaults.Keys.isFirstVisit
    private let LAST_SOUND_KEY = UserDefaults.Keys.lastPlayedSoundKey
    
}

// MARK: - Data Get, Set Properties
extension UserDefaultsManager {
    
    var customSounds: [CustomSound] {
        get {
            guard let customSoundsData = standard.data(forKey: CUSTOM_SOUND_KEY) else {
                return []
            }
            do {
                let decoder = JSONDecoder()
                let customSounds = try decoder.decode([CustomSound].self, from: customSoundsData)
                return customSounds
            } catch {
                print("Error decoding custom sounds: \(error)")
                return []
            }
        }
        
        set {
            do {
                let encoder = JSONEncoder()
                let customSoundsData = try encoder.encode(newValue)
                standard.set(customSoundsData, forKey: CUSTOM_SOUND_KEY)
            } catch {
                print("Error encoding custom sounds: \(error)")
            }
        }
    }
    
    /// 번들에 내장된 프리셋 세트의 버전. 이 값이 올라가면 기존 설치에서도 프리셋을 다시 시드한다.
    var presetSeedVersion: Int {
        get { standard.integer(forKey: UserDefaults.Keys.presetSeedVersion) }
        set { standard.set(newValue, forKey: UserDefaults.Keys.presetSeedVersion) }
    }

    var isFirstVisit: Bool {
        get {
            if standard.object(forKey: IS_FIRST_VISIT) == nil {
                return true
            } else {
                return standard.bool(forKey: IS_FIRST_VISIT)
            }
        }
        set {
            standard.set(newValue, forKey: IS_FIRST_VISIT)
        }
    }

    var lastPlayedSound: CustomSound {
        get {
            if customSounds.isEmpty {
                return CustomSound()
            } else {
                return customSounds.first ?? CustomSound()
            }
        }
        set(newSound) {
            let data = try? JSONEncoder().encode(newSound)
            standard.set(data, forKey: LAST_SOUND_KEY)
        }
    }

}

// MARK: - Methods
extension UserDefaultsManager {
    
    func removeOneCustomSound(at index: Int) {
        var customSounds = self.customSounds
        customSounds.remove(at: index)
        self.customSounds = customSounds
    }
    
    func removeAllCustomSounds() {
        standard.removeObject(forKey: CUSTOM_SOUND_KEY)
    }
    
}
