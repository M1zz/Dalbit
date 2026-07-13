//
//  TimerAlarmPagerView.swift
//  Dalbit
//
//  홈에서 달 위로 스와이프하면 나오는 페이지.
//  세그먼트 컨트롤로 [수면타이머 | 알람]을 구분해서 보여준다.
//

import SwiftUI

struct TimerAlarmPagerView: View {

    @ObservedObject var timerManager: TimerManager
    /// TimerView가 사용하는 표시 상태 (false로 set 시 홈으로 닫힘)
    @Binding var isShowingTimer: Bool
    /// 홈으로 닫기(아래로) 콜백
    var onClose: () -> Void

    enum Segment: Int, CaseIterable {
        case timer   // 수면타이머
        case alarm   // 알람

        var title: String {
            switch self {
            case .timer: return L.Alarm.segmentTimer.localized
            case .alarm: return L.Alarm.title.localized
            }
        }
    }

    @State private var segment: Segment = .timer
    @State private var showNewAlarm = false

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                topBar

                switch segment {
                case .timer:
                    TimerView(timerManager: timerManager, isShowingTimer: $isShowingTimer)
                case .alarm:
                    AlarmListView(embedded: true,
                                  onRequestAdd: { showNewAlarm = true })
                }
            }
        }
        // 새 알람 만들기
        .navigationDestination(isPresented: $showNewAlarm) {
            AlarmEditView(mode: .create)
        }
    }

    // MARK: - Top Bar (닫기 + 세그먼트 + 추가)

    private var topBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button(action: onClose) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.Common.close.localized)

            Picker("", selection: $segment) {
                ForEach(Segment.allCases, id: \.self) { seg in
                    Text(seg.title).tag(seg)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)

            // 알람 세그먼트에서만 추가(+) 버튼. 타이머는 자체 시작/리셋 컨트롤 사용.
            Group {
                if segment == .alarm {
                    Button(action: { showNewAlarm = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(DS.Colors.accent)
                    }
                    .accessibilityLabel(L.Alarm.add.localized)
                } else {
                    Color.clear
                }
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .background(.ultraThinMaterial)
    }
}
