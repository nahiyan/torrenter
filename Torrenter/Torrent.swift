//
//  Torrent.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/2/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation
import CoreData

class Torrent: NSObject {
    var index: Int = 0
    let id: NSManagedObjectID
    
    init(_ id: NSManagedObjectID) {
        self.index = Int(torrent_count())
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
        get {
            return String(cString: self.getInfo().name)
        }
    }
    
    @objc var isSeeding: Bool {
        get {
            return self.getInfo().is_seeding
        }
    }
    
    @objc var isFinished: Bool {
        get {
            return self.getInfo().is_finished
        }
    }
    
    @objc var seeds: String {
        get {
            return String(format:"%d / %d", self.getInfo().num_seeds, self.getInfo().list_seeds)
        }
    }
    
    @objc var peers: String {
        get {
            return String(format:"%d / %d", self.getInfo().num_peers, self.getInfo().list_peers)
        }
    }
    
    @objc var downloadRate: String {
        get {
            let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(self.getInfo().download_rate))
            
            if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
                return String(format:"%.2f %@", dataTransferRate.value, dataTransferRate.unit)
            } else {
                return String(format:"%.0f %@", dataTransferRate.value, dataTransferRate.unit)
            }
        }
    }
    
    @objc var uploadRate: String {
        get {
            let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(self.getInfo().upload_rate))
            
            if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
                return String(format:"%.2f %@", dataTransferRate.value, dataTransferRate.unit)
            } else {
                return String(format:"%.0f %@", dataTransferRate.value, dataTransferRate.unit)
            }
        }
    }
    
    @objc var progress: String {
        get {
            return String(format: "%.1f%%", self.getInfo().progress * 100)
        }
    }
    
    @objc var status: String {
        get {
            var status: String;
            
            switch self.getInfo().status {
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
    }
    
    @objc var isPaused: Bool {
        get {
            return torrent_is_paused(Int32(index))
        }
    }
    
    func pause() -> Void {
        torrent_pause(Int32(index))
    }
    
    func resume() -> Void {
        torrent_resume(Int32(index))
    }
    
}
