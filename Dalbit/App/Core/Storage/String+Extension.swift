//
//  String+Extension.swift
//  Dalbit
//
//  Created by Doyeon on 2023/05/18.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
