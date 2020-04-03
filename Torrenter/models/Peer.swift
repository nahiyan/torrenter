//
//  Peer.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/24/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class Peer: NSObject {
    let index: Int
    let _ipAddress: String

    init(_ index: Int, _ info: PeerInfo) {
        self.index = index
        _ipAddress = String(cString: info.ip_address)
    }

    @objc var ipAddress: String {
        return _ipAddress
    }
}
