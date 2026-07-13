//
//  Enums.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/17.
//

/**
 Enum으로 관리되는 모든 것
 */

import Foundation

/// 탭 바 아이템
enum TabItems: String {
    case listen = "tab.listen"

    var localizedName: String {
        return self.rawValue.localized
    }
}

/// 탭 바 아이콘 파일 이름
enum TabBarIcon: String {
    case listen = "headphones"
}

/// 음악 파일 확장자를 하드코딩하지 않기 위해 생성한 객체
enum MusicExtension: String {
    case mp3
    case wav
}

/// 파일 확장자를 하드코딩하지 않기 위해 생성한 객체
enum FileExtension: String {
    case json
    case png
    case jpg
    case jpeg
}

enum PlayerButton: String {
    case play = "play"
    case pause = "pause"
    case fastForward = "fast_forward"
    case fastRewind = "fast_rewind"
}

// CircularSlider에 쓰이는 Icon
enum FeatureIcon: String {
    case filter = "filter"
    case volume = "volume"
    case pitch = "pitch"
    case interval = "interval"
    // SoundDetailView에서만 쓰이는 이미지
    case headset = "headset"
}

  // 온보딩 관련
enum OnboardInfo {
    // 아이콘 파일이름
    enum IconName: String {
        case Equalizer = "Equalizer"
        case Headphone = "Headphone"
        case Lamp = "Lamp"
        case Musicplayer = "Musicplayer"
    }
    // 설명 문구
    enum IconText: String {
        case Equlizer = "onboarding.desc1"
        case Headphone = "onboarding.desc2"
        case Lamp = "onboarding.desc3"
        case Musicplayer = "onboarding.desc4"

        var localizedText: String {
            return self.rawValue.localized
        }
    }
}

enum SelectSound: String {
    case checked_circle
    case unchecked_circle
}

enum TimerButton: String {
    case reset_activated
    case reset_deactivated
    case start_circle
    case pause_circle
    case resume_circle
}
