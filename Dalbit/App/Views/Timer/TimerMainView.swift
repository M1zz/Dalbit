//
//  TimerMainView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/03/09.
//

import SwiftUI

/**
 타이머 View
 타이머를 설정하기 전의 View
 설정한 시간만큼 특정 음원을 반복 재생하는 기능
 */
struct TimerMainView: View {
    
    @EnvironmentObject var viewModel: CustomSoundViewModel
    @ObservedObject var timerManager = TimerManager(viewModel: CustomSoundViewModel())
    @State private var hours : [Int] = Array(0...23)
    @State private var minutes : [Int] = Array(0...59)
    @State var isShowingSelectorView: Bool = false
    @State var isShowingTimerProgressView: Bool = false
    @State var progress: Double = 1.0
    @State private var selectedSoundText: String = ""
    
    var body: some View {
        
        ZStack {
            Color(.DefaultBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Text(L.Timer.title.localized)
                    .foregroundColor(Color(.TitleText))
                    .font(.system(size: 24, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                VStack {
                    
                    Spacer()
                    
                    if isShowingTimerProgressView == false {
                        TimePickerView(hours: $hours,
                                       minutes: $minutes,
                                       selectedTimeIndexHours: $timerManager.selectedTimeIndexHours,
                                       selectedTimeIndexMinutes: $timerManager.selectedTimeIndexMinutes)
                    } else {
                        TimerProgressView(timerManager: timerManager)
                    }
                }
                
                Spacer()
                
                VStack {
                    Button {
                        isShowingSelectorView.toggle()
                    } label: {
                        selectSoundButton()
                            .cornerRadius(10)
                            .padding(.horizontal, 38)
                            .padding(.vertical, 50)
                    }

                    .navigationDestination(isPresented: $isShowingSelectorView) {
                        TimerSoundSelectModalView()
                    }

                    Spacer()
                    
                    HStack {
                        // 왼쪽 버튼(리셋)
                        Button {
                            timerManager.stopTimer(timerManager: timerManager)
                            isShowingTimerProgressView = false
                        } label: {
                            if isShowingTimerProgressView {
                                Image(TimerButton.reset_activated.rawValue)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                            } else {
                                Image(TimerButton.reset_deactivated.rawValue)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                            }
                        }
                        
                        Spacer ()
                        
                        // 오른쪽 버튼(시작, 중단)
                        Button {
                            if isShowingTimerProgressView {
                                if let timer = timerManager.textTimer {
                                    if timer.isValid {
                                        timerManager.pauseTimer(timerManager: timerManager)
                                    }
                                } else {
                                    timerManager.resumeTimer(timerManager: timerManager)
                                    if let sound = viewModel.selectedSound {
                                        viewModel.play(with: sound)
                                    }
                                }
                            } else {
                                if let sound = viewModel.selectedSound {
                                    viewModel.play(with: sound)
                                }
                                isShowingTimerProgressView = true
                            }
                        } label: {
                            if isShowingTimerProgressView == false {
                                Image(TimerButton.start_circle.rawValue)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                            } else {
                                if let timer = timerManager.textTimer {
                                    if timer.isValid {
                                        Image(TimerButton.pause_circle.rawValue)
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                    }
                                } else {
                                    Image(TimerButton.start_circle.rawValue)
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                }
                
                
            }
        }
        .onAppear {
            timerManager.viewModel = viewModel
            timerManager.timerDidFinish = {
                self.isShowingTimerProgressView = false
            }
        }
    }
    
    @ViewBuilder
    private func selectSoundButton() -> some View {
        HStack {
            Text(viewModel.selectedSound?.title ?? L.SaveView.selectYourSound.localized)
                .foregroundColor(Color(.TimerMyListText))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(.TimerMyListText))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .background(Color(.TimerMyListBackground))
    }
    
}

struct RelaxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            TimerMainView()
                .environmentObject(CustomSoundViewModel())
        }
    }
}

