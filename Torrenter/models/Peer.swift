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
    var info: PeerInfo

    init(_ index: Int) {
        self.index = index
        info = torrent_get_peer_info(Int32(index))
    }

    func fetchInfo() {
        info = torrent_get_peer_info(Int32(index))
    }

    @objc var ipAddress: String {
        return String(cString: info.ip_address)
    }
}
