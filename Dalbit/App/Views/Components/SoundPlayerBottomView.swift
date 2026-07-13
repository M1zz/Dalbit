//
//  SoundPlayerBottomView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

import SwiftUI

/**
 앱 내부 하단에 위치한 플레이어 바 형태의 View
 */
struct SoundPlayerBottomView: View {
    
    @EnvironmentObject var viewModel: CustomSoundViewModel
    
    var body: some View {
        
        HStack {
            Image(viewModel.selectedSound?.category.imageName ?? viewModel.lastSound.category.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .background(Color(hex: viewModel.selectedSound?.color ?? viewModel.lastSound.color))
                .cornerRadius(8)
            
            Text(viewModel.selectedSound?.title ?? viewModel.lastSound.title)
                .font(.system(size: 18, weight: .bold))
                .padding(.leading, 20)
                .foregroundColor(Color(.Text))
            
            Spacer()
            
            Button(action: {
                if viewModel.isPlaying {
                    viewModel.stopSound()
                } else {
                    viewModel.play(with: viewModel.selectedSound ?? viewModel.lastSound)
                }
            }) {
                Image(viewModel.playPauseStatusImage)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(.Text))
                    .frame(width: 20, height: 20)
                    .scaledToFit()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.SoundPlayerBottom))
        
        .onAppear {
            viewModel.loadSound()
        }
    }
}

struct BottomSoundPlayerBarView_Previews: PreviewProvider {
    static var previews: some View {
        SoundPlayerBottomView()
    }
}
