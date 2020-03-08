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
    let id: NSManagedObjectID

    init(_ id: NSManagedObjectID) {
        index = Int(torrent_count())
        self.id = id
    }

    init(_ index: Int, _ id: NSManagedObjectID) {
        self.index = index
        self.id = id
    }

    func getInfo() -> TorrentInfo {
        return torrent_get_info(Int32(index))
    }

    @objc var name: String {
        return String(cString: getInfo().name)
    }

    @objc var isSeeding: Bool {
        return getInfo().is_seeding
    }

    @objc var isFinished: Bool {
        return getInfo().is_finished
    }

    @objc var seeds: String {
        return String(format: "%d / %d", getInfo().num_seeds, getInfo().list_seeds)
    }

    @objc var peers: String {
        return String(format: "%d / %d", getInfo().num_peers, getInfo().list_peers)
    }

    @objc var downloadRate: String {
        let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(getInfo().download_rate))

        if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
            return String(format: "%.2f %@", dataTransferRate.value, dataTransferRate.unit)
        } else {
            return String(format: "%.0f %@", dataTransferRate.value, dataTransferRate.unit)
        }
    }

    @objc var uploadRate: String {
        let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(getInfo().upload_rate))

        if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
            return String(format: "%.2f %@", dataTransferRate.value, dataTransferRate.unit)
        } else {
            return String(format: "%.0f %@", dataTransferRate.value, dataTransferRate.unit)
        }
    }

    @objc var progress: String {
        return String(format: "%.1f%%", getInfo().progress * 100)
    }

    @objc var status: String {
        var status: String

        switch getInfo().status {
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
