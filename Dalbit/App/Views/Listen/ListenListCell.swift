//
//  ListenListCell.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

import SwiftUI

/**
 커스텀 음원의 각 정보가 셀 안에 노출되는 View
 */
struct ListenListCell: View {
    
    var customSound: CustomSound
    
    var body: some View {
        VStack {
            HStack {
                // 레이어 사운드면 썸네일, 아니면 기존 이미지
                if customSound.isLayeredSound {
                    SoundThumbnailView(sound: customSound, size: 60)
                        .cornerRadius(8)
                } else {
                    Image(customSound.category.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .background(Color(hex: customSound.color))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(customSound.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(.Text))

                    // 레이어 개수 표시
                    if let layers = customSound.soundLayers, layers.count > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "square.3.layers.3d")
                                .font(.system(size: 10))
                            Text("\(layers.count)개 레이어")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(.PrimaryPurple).opacity(0.8))
                    }
                }
                .padding(.leading, 20)

                Spacer()
            }
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.ListenListCellUnderLine))
                .padding(.vertical, 2)
                .background(Color(.DefaultBackground))
                .offset(y: 12)
        }
        .background(Color(.DefaultBackground))
    }
}

struct ListenListCell_Previews: PreviewProvider {
    static var previews: some View {
        ListenListCell(customSound: CustomSound(title: "임시 타이틀", category: .WaterDrop, variation: .init(), filter: .WaterDrop, color: ""))
    }
}
