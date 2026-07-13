//
//  SearchBarView.swift
//  RelaxOn
//
//  Created by Doyeon on 2023/05/18.
//

import SwiftUI

/**
 검색창 View
 */
struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(
                    text.isEmpty ?
                    Color(.SearchBarText) : Color(.SearchBarText))

            TextField(L.SoundList.searchPlaceholder.localized, text: $text)
                .autocorrectionDisabled(true)
                .foregroundColor(Color(.SearchBarText))
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .padding()
                        .offset(x: 10)
                        .foregroundColor(Color(.SearchBarText))
                        .opacity(text.isEmpty ? 0.0 : 1.0)
                        .onTapGesture {
                            text = ""
                            UIApplication.shared.endEditing()
                        }
                    , alignment: .trailing
                )
        }
        .font(.system(size: 14))
        .frame(minHeight: 40)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.SearchBarBackground))
        )
    }
}


struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant("저장한 나만의 소리를 검색해보세요"))
    }
}

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
