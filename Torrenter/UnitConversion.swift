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

    static let minute: Float = 60
    static let hour: Float = 3600
    static let day: Float = 86400
    static let month: Float = 2_592_000
    static let year: Float = 946_080_000

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

    static func timeAuto(_ value: Float) -> Time {
        if value < minute {
            return Time(value, "seconds")
        } else if value >= minute, value < hour {
            return Time(value / minute, "minutes")
        } else if value >= hour, value < day {
            return Time(value / hour, "hours")
        } else if value >= day, value < month {
            return Time(value / day, "days")
        } else if value >= month, value < year {
            return Time(value / month, "months")
        } else {
            return Time(value / year, "years")
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

struct Time {
    let value: Float
    let unit: String

    init(_ value: Float, _ unit: String) {
        self.value = value
        self.unit = unit
    }
}
