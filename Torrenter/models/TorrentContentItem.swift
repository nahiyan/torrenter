//
//  TorrentFile.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/9/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class TorrentContentItem: NSObject {
    let name: String
    var children: [TorrentContentItem]

    init(_ name: String) {
        self.name = name
        children = []
    }
}
