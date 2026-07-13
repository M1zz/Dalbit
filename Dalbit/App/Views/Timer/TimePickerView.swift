//
//  TimePickerView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/27.
//

import SwiftUI

struct TimePickerView: View {
    @Binding var hours: [Int]
    @Binding var minutes: [Int]
    @Binding var selectedTimeIndexHours: Int
    @Binding var selectedTimeIndexMinutes: Int
    
    var body: some View {
        HStack {
            Spacer ()
            
            HStack(alignment: .center, spacing: DS.Spacing.xs) {
                Picker(L.A11y.hoursPicker.localized, selection: $selectedTimeIndexHours, content: {
                    ForEach(hours, id: \.self) {
                        index in
                        Text("\(hours[index])").tag(index)
                    }
                })
                .pickerStyle(.wheel)
                .frame(width: 72)
                .clipped()
                .accessibilityLabel(L.A11y.hoursPicker.localized)

                Text(L.Timer.hours.localized)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DS.Colors.textSecondary)
                    .fixedSize()
                    .lineLimit(1)
                    .accessibilityHidden(true)

                Picker(L.A11y.minutesPicker.localized, selection: $selectedTimeIndexMinutes, content: {
                    ForEach(minutes, id: \.self) {
                        index in
                        Text("\(minutes[index])").tag(index)
                    }
                })
                .pickerStyle(.wheel)
                .frame(width: 72)
                .clipped()
                .accessibilityLabel(L.A11y.minutesPicker.localized)

                Text(L.Timer.minutes.localized)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DS.Colors.textSecondary)
                    .fixedSize()
                    .lineLimit(1)
                    .accessibilityHidden(true)
            }
            .padding(DS.Spacing.md)

            Spacer ()
        }
    }
}


struct TimePickerView_Previews: PreviewProvider {
    static var previews: some View {
        TimePickerView(hours: .constant(Array(0...23)), minutes: .constant(Array(0...59)), selectedTimeIndexHours: .constant(1), selectedTimeIndexMinutes: .constant(1))
    }
}
