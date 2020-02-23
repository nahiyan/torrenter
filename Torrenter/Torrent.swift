//
//  Torrent.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/23/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class Torrent: NSObject {
    let index: Int

    init(_ index: Int) {
        self.index = index
    }
    
    func getInfo() -> TorrentInfo {
        return torrent_get_info(Int32(index))
    }
    
    @objc var name: String {
        get {
            return String(cString: self.getInfo().name)
        }
    }
    
    @objc var is_seeding: Bool {
        get {
            return self.getInfo().is_seeding
        }
    }
    
    @objc var is_finished: Bool {
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
    
    @objc var download_rate: String {
        get {
            let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(self.getInfo().download_rate))
            
            if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
                return String(format:"%.2f %@", dataTransferRate.value, dataTransferRate.unit)
            } else {
                return String(format:"%.0f %@", dataTransferRate.value, dataTransferRate.unit)
            }
        }
    }
    
    @objc var upload_rate: String {
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
            switch self.getInfo().status {
            case state_t(rawValue: 1):
                return "Checking files"
            case state_t(rawValue: 2):
                return "Downloading metadata"
            case state_t(rawValue: 3):
                return "Downloading"
            case state_t(rawValue: 4):
                return "Finished"
            case state_t(rawValue: 5):
                return "Seeding"
            case state_t(rawValue: 6):
                return "Allocating"
            default:
                return "Checking resume data"
            }
            
        }
    }
}
