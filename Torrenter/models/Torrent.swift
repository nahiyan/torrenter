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

    @objc var _seeds: Int32 {
        info.num_seeds
    }

    @objc var peers: String {
        return String(format: "%d / %d", info.num_peers, info.list_peers)
    }

    @objc var _peers: Int32 {
        info.num_peers
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

    @objc var _size: Float {
        return info.size
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

    @objc var addedOn: String {
        let date = Date(timeIntervalSince1970: Double(info.added_on))

        let dateformatter = DateFormatter()
        dateformatter.locale = Locale.current
        dateformatter.dateStyle = DateFormatter.Style.medium
        dateformatter.timeStyle = DateFormatter.Style.short

        return dateformatter.string(from: date)
    }

    @objc var createdOn: String {
        if info.created_on == -1 || info.created_on == 0 {
            return "N/A"
        } else {
            let date = Date(timeIntervalSince1970: Double(info.created_on))

            let dateformatter = DateFormatter()
            dateformatter.locale = Locale.current
            dateformatter.dateStyle = DateFormatter.Style.medium
            dateformatter.timeStyle = DateFormatter.Style.short

            return dateformatter.string(from: date)
        }
    }

    @objc var completedOn: String {
        if info.progress == 1 {
            let date = Date(timeIntervalSince1970: Double(info.completed_on))

            let dateformatter = DateFormatter()
            dateformatter.locale = Locale.current
            dateformatter.dateStyle = DateFormatter.Style.medium
            dateformatter.timeStyle = DateFormatter.Style.short

            return dateformatter.string(from: date)
        } else {
            return "N/A"
        }
    }

    @objc var shareRatio: String {
        let shareRatio: Float = Float(info.downloaded) / Float(info.uploaded)

        if shareRatio.isInfinite || shareRatio.isNaN {
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

    @objc var _downloadRate: Int32 {
        return info.download_rate
    }

    @objc var uploadRate: String {
        let data: Data = UnitConversion.dataAuto(Float(info.upload_rate))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@/s", data.value, data.unit)
        } else {
            return String(format: "%.0f %@/s", data.value, data.unit)
        }
    }

    @objc var _uploadRate: Int32 {
        return info.upload_rate
    }

    @objc var progress: String {
        return String(format: "%.1f%%", info.progress * 100)
    }

    @objc var _progress: Float {
        return info.progress
    }

    @objc var downloadProgress: String {
        if info.total_wanted > 0 {
            return String(format: "%.1f%%", (info.total_wanted_done / info.total_wanted) * 100)
        } else {
            return "0.0%"
        }
    }

    @objc var infoHash: String {
        return String(cString: info.info_hash)
    }

    @objc var comment: String {
        return String(cString: info.comment)
    }

    @objc var creator: String {
        return String(cString: info.creator)
    }

    @objc var pieces: String {
        let pieceSize: Data = UnitConversion.dataAutoDiscrete(Float(info.piece_size))

        return String(format: "%d x %.0f " + pieceSize.unit + " (have %d)", info.num_pieces_total, pieceSize.value, info.num_pieces)
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
        let vc: ViewController? = ViewController.get()

        if vc != nil {
            torrent_sequential(Int32(index), true)

            vc!.updateActionButtonsAndDetailsView()
        }
    }

    func nonSequential() {
        let vc: ViewController? = ViewController.get()

        if vc != nil {
            torrent_sequential(Int32(index), false)

            vc!.updateActionButtonsAndDetailsView()
        }
    }

    func forceRecheck() {
        torrent_force_recheck(Int32(index))
    }

    func forceReannounce() {
        torrent_force_reannounce(Int32(index))
    }

    func pause() {
        let vc: ViewController? = ViewController.get()

        if vc != nil {
            torrent_pause(Int32(index))

            vc!.updateActionButtonsAndDetailsView()
        }
    }

    func resume() {
        let vc: ViewController? = ViewController.get()

        if vc != nil {
            torrent_resume(Int32(index))

            vc!.updateActionButtonsAndDetailsView()
        }
    }

    func remove() {
        let vc: ViewController? = ViewController.get()

        if vc != nil {
            let windowController: WindowController = NSApplication.shared.mainWindow!.windowController as! WindowController

            // Remove torrent from array
            vc!.torrents.removeObject(self)

            // Remove torrent from session and unordered map along with its resume data
            torrent_remove(Int32(index))

            // Reset table selection
            vc!.torrentsTable.deselectAll(nil)
            vc!.torrentDetails.hide()
            windowController.deactivateButtons()
        }
    }
}
