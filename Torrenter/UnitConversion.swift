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
            if value > 1 {
                return Time(value, "seconds")
            } else {
                return Time(value, "second")
            }
        } else if value >= minute, value < hour {
            let minutes: Float = value / minute

            if minutes > 1 {
                return Time(minutes, "minutes")
            } else {
                return Time(minutes, "minute")
            }
        } else if value >= hour, value < day {
            let hours: Float = value / hour

            if hours > 1 {
                return Time(hours, "hours")
            } else {
                return Time(hours, "hour")
            }
        } else if value >= day, value < month {
            let days: Float = value / day

            if days > 1 {
                return Time(days, "days")
            } else {
                return Time(days, "day")
            }
        } else if value >= month, value < year {
            let months: Float = value / month

            if months > 1 {
                return Time(months, "months")
            } else {
                return Time(months, "month")
            }
        } else {
            let years: Float = value / year

            if years > 1 {
                return Time(years, "years")
            } else {
                return Time(years, "year")
            }
        }
    }

    static func timeAutoDiscrete(_ value: Float) -> Time {
        if value.isInfinite || value.isNaN {
            return Time(0.0, "second")
        } else {
            if value < minute {
                let seconds: Float = value.rounded()

                if seconds > 1 {
                    return Time(seconds, "seconds")
                } else {
                    return Time(seconds, "second")
                }
            } else if value >= minute, value < hour {
                let minutes: Float = (value / minute).rounded()

                if minutes > 1 {
                    return Time(minutes, "minutes")
                } else {
                    return Time(minutes, "minute")
                }
            } else if value >= hour, value < day {
                let hours: Float = (value / hour).rounded()

                if hours > 1 {
                    return Time(hours, "hours")
                } else {
                    return Time(hours, "hour")
                }
            } else if value >= day, value < month {
                let days: Float = (value / day).rounded()

                if days > 1 {
                    return Time(days, "days")
                } else {
                    return Time(days, "day")
                }
            } else if value >= month, value < year {
                let months: Float = (value / month).rounded()

                if months > 1 {
                    return Time(months, "months")
                } else {
                    return Time(months, "month")
                }
            } else {
                let years: Float = (value / year).rounded()

                if years > 1 {
                    return Time(years, "years")
                } else {
                    return Time(years, "year")
                }
            }
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
