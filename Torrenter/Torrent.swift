//
//  Torrent.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/2/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class Torrent: NSObject {
    var index: Int = 0
    var info: TorrentInfo

    init(_ index: Int) {
        self.index = index
        info = torrent_get_info(Int32(index))
    }

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
        if info.download_limit <= 0 {
            return String("\u{221E}")
        } else {
            let data: Data = UnitConversion.dataAuto(Float(info.download_limit))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@/s", data.value, data.unit)
            } else {
                return String(format: "%.0f %@/s", data.value, data.unit)
            }
        }
    }

    @objc var uploadLimit: String {
        if info.upload_limit <= 0 {
            return "\u{221E}"
        } else {
            let data: Data = UnitConversion.dataAuto(Float(info.upload_limit))

            if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
                return String(format: "%.2f %@/s", data.value, data.unit)
            } else {
                return String(format: "%.0f %@/s", data.value, data.unit)
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
        let time: Time = UnitConversion.timeAutoDiscrete(Float(info.next_announce))
        return String(format: "%.0f %@", time.value, time.unit)
    }

    @objc var activeDuration: String {
        let time: Time = UnitConversion.timeAutoDiscrete(Float(info.active_duration))
        return String(format: "%.0f %@", time.value, time.unit)
    }

    @objc var size: String {
        let size: Data = UnitConversion.dataAuto(info.size)

        if size.unit == "MB" || size.unit == "GB" || size.unit == "TB" {
            return String(format: "%.2f %@", size.value, size.unit)
        } else {
            return String(format: "%.0f %@", size.value, size.unit)
        }
    }

    @objc var timeRemaining: String {
        let downloadRate: Float = Float(info.download_rate)
        let downloadLeft: Float = info.total_wanted - info.total_wanted_done
        let timeRemaining: Time = UnitConversion.timeAutoDiscrete(downloadLeft / downloadRate)

        if info.status != state_t(rawValue: 3) {
            return "-"
        } else {
            return String(format: "%.0f %@", timeRemaining.value, timeRemaining.unit)
        }
    }

    @objc var shareRatio: String {
        let shareRatio: Float = Float(info.downloaded) / Float(info.uploaded)

        if shareRatio.isInfinite {
            return "-"
        } else {
            return String(format: "%.2f", shareRatio)
        }
    }

    @objc var downloadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.download_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@/s", data.value, data.unit)
        } else {
            return String(format: "%.0f %@/s", data.value, data.unit)
        }
    }

    @objc var uploadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.upload_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@/s", data.value, data.unit)
        } else {
            return String(format: "%.0f %@/s", data.value, data.unit)
        }
    }

    @objc var progress: String {
        // return info.progress
        return String(format: "%.1f%%", info.progress * 100)
    }

    @objc var status: String {
        var status: String

        if isPaused {
            status = "Paused"
        } else {
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
        }

        return status
    }

    @objc var isPaused: Bool {
        return torrent_is_paused(Int32(index))
    }

    @objc var savePath: String {
        return String(cString: info.save_path)
    }

    @objc var isSequential: Bool {
        return torrent_is_sequential(Int32(index))
    }

    func sequential() {
        torrent_sequential(Int32(index), true)
    }

    func nonSequential() {
        torrent_sequential(Int32(index), false)
    }

    func forceRecheck() {
        torrent_force_recheck(Int32(index))
    }

    func forceReannounce() {
        torrent_force_reannounce(Int32(index))
    }

    func pause() {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        torrent_pause(Int32(index))

        viewController.updateActionButtonsAndDetailsView()
    }

    func resume() {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        torrent_resume(Int32(index))

        viewController.updateActionButtonsAndDetailsView()
    }

    func remove() {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController
        let windowController: WindowController = NSApplication.shared.mainWindow!.windowController as! WindowController

        // Remove torrent from array
        viewController.torrents.removeObject(self)

        // Remove torrent from session and unordered map along with its resume data
        torrent_remove(Int32(index))

        // Reset table selection
        viewController.torrentsTable.deselectAll(nil)
        viewController.hideDetails()
        windowController.deactivateButtons()
    }
}
