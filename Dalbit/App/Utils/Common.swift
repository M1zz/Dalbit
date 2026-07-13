//
//  Common.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/17.
//

/**
 Public 하게 쓰여지는 프로퍼티 & 함수 등
 */

import Foundation

/**
 Bundle에 있는 mp3 파일 경로 불러오는 기능
 */
func getPathUrl(forResource: String, musicExtension: MusicExtension) -> URL? {
    Bundle.main.url(forResource: forResource, withExtension: musicExtension.rawValue) ?? nil
}

func getPathNSURL(forResource: String, musicExtension: MusicExtension) -> NSURL? {
    return Bundle.main.url(forResource: forResource, withExtension: musicExtension.rawValue) as NSURL?
}

/**
 SoundDetailView의 프로퍼티
 */

enum CircleType: String, CaseIterable, Identifiable {
    static var all: [CircleType] { CircleType.allCases.sorted(by: { $0.width > $1.width }) }

    case xSmall
    case small
    case medium
    case large

    var id: String { self.rawValue }
    var width: CGFloat {
        switch self {
            
        case .xSmall:
            return 120
        case .small:
            return 210
        case .medium:
            return 250
        case .large:
            return 300
        }
    }
}

var pointAngle: [Double] = [-90, -18, 54, 126, -162]
var featureIcon: [String] = [FeatureIcon.interval.rawValue,
                             FeatureIcon.volume.rawValue,
                             FeatureIcon.pitch.rawValue,
                             FeatureIcon.filter.rawValue]
