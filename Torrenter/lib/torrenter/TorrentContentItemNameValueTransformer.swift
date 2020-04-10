//
//  TorrentContentItemNameValueTransformer.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/10/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class TorrentContentItemNameValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return false
    }

    override func transformedValue(_ value: Any?) -> Any? {
        print(value)

        return "FUck me all"
    }
}
