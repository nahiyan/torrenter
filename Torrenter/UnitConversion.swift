//
//  UnitConversion.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/22/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class UnitConversion {
    static let kilobyte: Float = 1024
    static let megabyte: Float = 1_048_576
    static let gigabyte: Float = 1_073_741_824
    static let terabyte: Float = 1_099_511_627_776

    static func dataAuto(_ value: Float) -> Data {
        if value < kilobyte {
            return Data(value, "B")
        } else if value >= kilobyte, value < megabyte {
            return Data(value / kilobyte, "KB")
        } else if value >= megabyte, value < gigabyte {
            return Data(value / megabyte, "MB")
        } else if value >= gigabyte, value < terabyte {
            return Data(value / gigabyte, "GB")
        } else {
            return Data(value / terabyte, "TB")
        }
    }
}

struct Data {
    let value: Float
    let unit: String

    init(_ value: Float, _ unit: String) {
        self.value = value
        self.unit = unit
    }
}
