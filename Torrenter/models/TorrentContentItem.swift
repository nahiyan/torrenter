//
//  TorrentFile.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/9/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class TorrentContentItem: NSObject {
    @objc dynamic let name: String
    @objc dynamic var enabled: Bool
    var children: [TorrentContentItem]?
    // var size: String {
    //     return "Size sucks"
    // }

    // var progress: String
    // var remaining: String
    // var availability: String

    init(_ name: String) {
        self.name = name
        children = []
        enabled = false
    }
}
