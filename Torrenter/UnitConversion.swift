//
//  UnitConversion.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/22/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class UnitConversion {
    static func dataTransferRate(_ value: Float) -> DataTransferRate {
        let kilobyte: Float = 1024
        let megabyte: Float = 1048576
        let gigabyte: Float = 1073741824
        let terabyte: Float = 1099511627776
        
        if value < kilobyte {
            return DataTransferRate(value, "B/s")
        } else if value >= kilobyte && value < megabyte {
            return DataTransferRate(value / kilobyte, "KB/s")
        } else if value >= megabyte && value < gigabyte {
            return DataTransferRate(value / megabyte, "MB/s")
        } else if value >= gigabyte && value < terabyte {
            return DataTransferRate(value / gigabyte, "GB/s")
        } else {
            return DataTransferRate(value / terabyte, "TB/s")
        }
    }
}

struct DataTransferRate {
    let value: Float
    let unit: String
    
    init(_ value: Float, _ unit: String) {
        self.value = value
        self.unit = unit
    }
}
