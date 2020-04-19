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

    @objc var client: String {
        return String(cString: info.client)
    }

    @objc var progress: String {
        return String(format: "%.1f%%", info.progress * 100)
    }

    @objc var uploadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.up_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@/s", data.value, data.unit)
        } else {
            return String(format: "%.0f %@/s", data.value, data.unit)
        }
    }

    @objc var downloadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.down_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@/s", data.value, data.unit)
        } else {
            return String(format: "%.0f %@/s", data.value, data.unit)
        }
    }

    @objc var totalDownloaded: String {
        let data: Data = UnitConversion.dataAuto(Float(info.total_down))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    @objc var totalUploaded: String {
        let data: Data = UnitConversion.dataAuto(Float(info.total_up))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    @objc var port: String {
        return String(format: "%d", info.port)
    }

    @objc var connectionType: String {
        switch info.connection_type {
        case 0:
            return "BitTorrent"
        case 1:
            return "WebSeed"
        default:
            return "HttpSeed"
        }
    }
}
