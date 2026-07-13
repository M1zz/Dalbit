//
//  OnboardItem.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/28.
//

import Foundation

enum OnboardButtonText: String {
    case `continue` = "계속"
    case start = "시작하기"
}

struct OnboardItem {
    let imageName: String
    let description: String
    let buttonText: String
    
    static func getAll() -> [OnboardItem] {
        return [
            OnboardItem(
                imageName: OnboardInfo.IconName.Lamp.rawValue,
                description: OnboardInfo.IconText.Lamp.rawValue,
                buttonText: OnboardButtonText.continue.rawValue
            ),
            OnboardItem(
                imageName: OnboardInfo.IconName.Equalizer.rawValue,
                description: OnboardInfo.IconText.Equlizer.rawValue,
                buttonText: OnboardButtonText.continue.rawValue
            ),
            OnboardItem(
                imageName: OnboardInfo.IconName.Musicplayer.rawValue,
                description: OnboardInfo.IconText.Musicplayer.rawValue,
                buttonText: OnboardButtonText.continue.rawValue
            ),
            OnboardItem(
                imageName: OnboardInfo.IconName.Headphone.rawValue,
                description: OnboardInfo.IconText.Headphone.rawValue,
                buttonText: OnboardButtonText.start.rawValue
            )
        ]
    }
}
