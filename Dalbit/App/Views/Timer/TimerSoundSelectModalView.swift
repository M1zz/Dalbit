//
//  TimerSoundSelectModalView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/28.
//

import SwiftUI

struct TimerSoundSelectModalView: View {
    
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        
        ZStack {
            ScreenBackground()

            VStack(spacing: DS.Spacing.md) {
                HStack {
                    Spacer()
                    Button(action: {
                        if let selectedSound = viewModel.selectedSound {
                            viewModel.setSelectedSound(selectedSound)
                        }
                        if viewModel.isPlaying {
                            viewModel.stopSound()
                            viewModel.play(with: viewModel.sound)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(L.Common.done.localized)
                            .font(DS.Font.headline())
                            .foregroundColor(DS.Colors.accent)
                            .padding(.horizontal, DS.Spacing.lg)
                            .padding(.vertical, DS.Spacing.sm)
                    }
                    .accessibilityLabel(L.A11y.closeButton.localized)
                }
                .padding(.horizontal, DS.Spacing.xs)

                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.bottom, DS.Spacing.xs)

                List {
                    ForEach(viewModel.filteredSounds) { file in
                        TimerSoundListCell(file: file)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .modifier(HiddenListBackgroundModifier())
            }
        }
        .onAppear {
            viewModel.loadSound()
        }
    }
}

// iOS 16+ 전용 List 배경 숨김 처리 (iOS 15 호환)
private struct HiddenListBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

struct TimerSoundSelectModalView_Previews: PreviewProvider {
    static var previews: some View {
        TimerSoundSelectModalView()
            .environmentObject(CustomSoundViewModel())
    }
}
