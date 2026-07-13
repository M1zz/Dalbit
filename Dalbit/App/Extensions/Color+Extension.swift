//
//  Color+Extension.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

import SwiftUI

/// Asset에 있는 CustomColorSet을 하드코딩 하지 않고 사용하기 위한 객체
enum CustomColor: String {
    case PrimaryPurple
    case DefaultBackground
    case TextFieldUnderLine
    case Text
    case ChevronBack
    case TitleText
    case ListenListCellUnderLine
    case SoundPlayerBottom
    case TimerMyListText
    case TimerMyListBackground
    case SearchBarText
    case SearchBarBackground
    case SelectedPage
    case UnselectedPage
    case CircularSliderBackground
    case CircularSliderLine
}

enum CustomSoundImageBackgroundColor: String, CaseIterable {
    case A = "8BBBE7"
    case B = "A399E0"
    case C = "ACACAC"
    case D = "ACD6A6"
    case E = "C9F4AE"
    case F = "DCE8F5"
    case G = "F3F1FF"
    case H = "F6CECE"
    case I = "FCEFAD"
    case J = "FDD0A8"
}

// MARK: - CustomColor를 사용하여 init 하는 기능
extension Color {
    init(_ customColor: CustomColor) {
        self.init(customColor.rawValue)
    }
}

// MARK: - CustomColor를 사용하여 init 하는 기능
extension Color {
    init(_ customSoundImageBackgroundColor: CustomSoundImageBackgroundColor) {
        self.init(customSoundImageBackgroundColor.rawValue)
    }
}

// MARK: - Color(hex:) 를 사용하여 #ffffff 와 같은 Hex 코드를 Color로 변환하여 init 하는 기능
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
