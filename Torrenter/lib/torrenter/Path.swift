//
//  UnitConversion.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/22/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class Path {
    static let homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path

    static func pathAuto(_ value: String) -> String {
        return value.replacingOccurrences(of: homeDirectory, with: "~")
    }
}
