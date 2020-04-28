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
    var info: PeerInfo?
    var country: UnsafePointer<CChar>?

    init(_ index: Int) {
        self.index = index
        info = nil
        super.init()
        fetchInfo()
    }

    func fetchInfo() {
        let _info: UnsafeMutablePointer<PeerInfo>? = torrent_get_peer_info(Int32(index))
        if _info != nil {
            info = _info!.pointee

            if country != nil {
                free(UnsafeMutableRawPointer(mutating: country!))
            }
            country = peer_get_country(info!.ip_address)
        } else {
            info = nil
        }
    }

    @objc var location: String {
        if country != nil, info != nil {
            return String(cString: country!)
        } else {
            return ""
        }
    }

    @objc var ipAddress: String {
        if info != nil {
            return String(cString: info!.ip_address)
        } else {
            return ""
        }
    }

    @objc var client: String {
        if info != nil {
            return String(cString: info!.client)
        } else {
            return ""
        }
    }

    @objc var progress: String {
        if info != nil {
            return String(format: "%.1f%%", info!.progress * 100)
        } else {
            return ""
        }
    }

    @objc var _progress: Float {
        return info!.progress
    }

    @objc var uploadRate: String {
        if info != nil {
            let data: Data = UnitConversion.dataAuto(Float(info!.up_rate))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@/s", data.value, data.unit)
            } else {
                return String(format: "%.0f %@/s", data.value, data.unit)
            }
        } else {
            return ""
        }
    }

    @objc var _uploadRate: Int32 {
        return info!.up_rate
    }

    @objc var downloadRate: String {
        if info != nil {
            let data: Data = UnitConversion.dataAuto(Float(info!.down_rate))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@/s", data.value, data.unit)
            } else {
                return String(format: "%.0f %@/s", data.value, data.unit)
            }
        } else {
            return ""
        }
    }

    @objc var _downloadRate: Int32 {
        return info!.down_rate
    }

    @objc var totalDownloaded: String {
        if info != nil {
            let data: Data = UnitConversion.dataAuto(Float(info!.total_down))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@", data.value, data.unit)
            } else {
                return String(format: "%.0f %@", data.value, data.unit)
            }
        } else {
            return ""
        }
    }

    @objc var _totalDownloaded: Int64 {
        return info!.total_down
    }

    @objc var totalUploaded: String {
        if info != nil {
            let data: Data = UnitConversion.dataAuto(Float(info!.total_up))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@", data.value, data.unit)
            } else {
                return String(format: "%.0f %@", data.value, data.unit)
            }
        } else {
            return ""
        }
    }

    @objc var _totalUploaded: Int64 {
        return info!.total_up
    }

    @objc var port: String {
        if info != nil {
            return String(format: "%d", info!.port)
        } else {
            return ""
        }
    }

    @objc var _port: UInt16 {
        return info!.port
    }

    @objc var connectionType: String {
        if info != nil {
            switch info!.connection_type {
            case 0:
                return "BitTorrent"
            case 1:
                return "WebSeed"
            default:
                return "HttpSeed"
            }
        } else {
            return ""
        }
    }

    @objc var _ipAddress: UInt {
        return info!._ip_address
    }
}
