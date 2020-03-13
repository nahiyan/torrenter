//
//  Torrent.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/2/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import CoreData
import Foundation

class Torrent: NSObject {
    var index: Int = 0
    // let id: NSManagedObjectID
    var info: TorrentInfo

    // init(_ id: NSManagedObjectID) {
    //     index = Int(torrent_next_index())
    //     self.id = id
    //     info = torrent_get_info(Int32(index))
    // }

    init(_ index: Int) {
        self.index = index
        info = torrent_get_info(Int32(index))
    }

    // init(_ index: Int, _ id: NSManagedObjectID) {
    //     self.index = index
    //     self.id = id
    //     info = torrent_get_info(Int32(index))
    // }

    func fetchInfo() {
        info = torrent_get_info(Int32(index))
    }

    @objc var name: String {
        return String(cString: info.name)
    }

    @objc var isSeeding: Bool {
        return info.is_seeding
    }

    @objc var isFinished: Bool {
        return info.is_finished
    }

    @objc var seeds: String {
        return String(format: "%d / %d", info.num_seeds, info.list_seeds)
    }

    @objc var peers: String {
        return String(format: "%d / %d", info.num_peers, info.list_peers)
    }

    @objc var connections: String {
        return String(format: "%d", info.connections)
    }

    @objc var wasted: String {
        let data: Data = UnitConversion.dataAuto(Float(info.wasted))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    @objc var downloadLimit: String {
        if info.download_limit == -1 {
            return String("\u{221E}")
        } else {
            let data: Data = UnitConversion.dataAuto(Float(info.download_limit))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@", data.value, data.unit)
            } else {
                return String(format: "%.0f %@", data.value, data.unit)
            }
        }
    }

    @objc var uploadLimit: String {
        if info.download_limit == -1 {
            return String("\u{221E}")
        } else {
            let data: Data = UnitConversion.dataAuto(Float(info.upload_limit))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@", data.value, data.unit)
            } else {
                return String(format: "%.0f %@", data.value, data.unit)
            }
        }
    }

    @objc var downloaded: String {
        let data: Data = UnitConversion.dataAuto(info.downloaded)

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    @objc var uploaded: String {
        let data: Data = UnitConversion.dataAuto(info.uploaded)

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    @objc var nextAnnounce: String {
        return String(format: "%d seconds", info.next_announce)
    }

    @objc var size: String {
        let size: Data = UnitConversion.dataAuto(info.size)

        if size.unit == "MB" || size.unit == "GB" || size.unit == "TB" {
            return String(format: "%.2f %@", size.value, size.unit)
        } else {
            return String(format: "%.0f %@", size.value, size.unit)
        }
    }

    @objc var shareRatio: String {
        let shareRatio: Float = Float(info.downloaded) / Float(info.uploaded)
        return String(format: "%.2f", shareRatio)
    }

    @objc var downloadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.download_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit + "/s")
        } else {
            return String(format: "%.0f %@", data.value, data.unit + "/s")
        }
    }

    @objc var uploadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.upload_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit + "/s")
        } else {
            return String(format: "%.0f %@", data.value, data.unit + "/s")
        }
    }

    @objc var progress: String {
        return String(format: "%.1f%%", info.progress * 100)
    }

    @objc var status: String {
        var status: String

        switch info.status {
        case state_t(rawValue: 1):
            status = "Checking files"
        case state_t(rawValue: 2):
            status = "Downloading metadata"
        case state_t(rawValue: 3):
            status = "Downloading"
        case state_t(rawValue: 4):
            status = "Finished"
        case state_t(rawValue: 5):
            status = "Seeding"
        case state_t(rawValue: 6):
            status = "Allocating"
        default:
            status = "Checking resume data"
        }

        if isPaused {
            status += " (Paused)"
        }

        return status
    }

    @objc var isPaused: Bool {
        return torrent_is_paused(Int32(index))
    }

    func pause() {
        torrent_pause(Int32(index))
    }

    func resume() {
        torrent_resume(Int32(index))
    }
}
