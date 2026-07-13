//
//  TimerProgressView.swift
//  RelaxOn
//
//  Created by 황석현 on 2023/04/26.
//

import SwiftUI

/**
 타이머가 작동되는 동안의 View
 */
struct TimerProgressView: View {
    
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        ZStack {
            timerManager.getCircularProgressBar()
            timerManager.getTimeText()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
}


struct TimerProgressView_Previews: PreviewProvider {
    static var previews: some View {
        TimerProgressView(timerManager: TimerManager(viewModel: .init()))
    }
}
