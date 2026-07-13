//
//  TimerSoundListCell.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/28.
//

import SwiftUI

struct TimerSoundListCell: View {
    
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @State private var isChecked = false
    var file: CustomSound
    
    var body: some View {
        VStack {
            HStack {
                Image(file.category.imageName)
                    .resizable()
                    .background(Color(hex: file.color))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                
                Text(file.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.Text))
                    .padding(.leading, 20)
                
                Spacer()
                
                Button(action: {
                    viewModel.selectedSound = file
                }) {
                    Image(viewModel.selectedSound == file ? SelectSound.checked_circle.rawValue : SelectSound.unchecked_circle.rawValue)
                        .foregroundColor(Color(.Text))
                }
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.ListenListCellUnderLine))
                .padding(.vertical, 2)
        }
        .background(Color(.DefaultBackground))
    }
}

struct TimerSoundListCell_Previews: PreviewProvider {
    static var previews: some View {
        TimerSoundListCell(file: CustomSound(title: "나의 물방울 소리", category: .WaterDrop, variation: AudioVariation(), filter: .WaterDrop))
            .environmentObject(CustomSoundViewModel())
    }
}
