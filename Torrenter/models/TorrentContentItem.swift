//
//  TorrentFile.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/9/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class TorrentContentItem: NSObject {
    @objc dynamic let name: String
    @objc dynamic var enabled: Bool {
        get {
            // Directory
            if children != nil {
                for child in children! {
                    if !child.enabled {
                        return false
                    }
                }

                return true
            } else {
                if info.priority == 0 {
                    return false
                } else {
                    return true
                }
            }
        }
        set {
            let priority: Int32
            if newValue {
                priority = 4
            } else {
                priority = 0
            }

            // Set the priority
            if children == nil {
                torrent_file_priority(Int32(torrentIndex), Int32(fileIndex), priority)
            } else {
                for child in children! {
                    child.enabled = newValue
                }
            }

            // Refresh content items
            let vc: ViewController? = ViewController.get()
            if vc != nil {
                info.priority = priority

                vc!.torrentDetails.reloadContentTable()
            }
        }
    }

    let fileIndex: Int
    var children: [TorrentContentItem]?
    var info: ContentItemInfo
    var priority: String {
        if info.priority <= 0 {
            return "Don't download"
        } else if info.priority >= 1, info.priority <= 3 {
            return "Low"
        } else if info.priority >= 4, info.priority <= 6 {
            return "Normal"
        } else {
            return "High"
        }
    }

    var size: String {
        let data: Data = UnitConversion.dataAuto(Float(info.size))

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    let torrentIndex: Int

    // var remaining: String
    // var availability: String

    init(name: String, fileIndex: Int, torrentIndex: Int) {
        self.name = name
        if fileIndex == -1 {
            children = nil
        } else {
            children = []
        }
        self.fileIndex = fileIndex
        if torrentIndex != -1, fileIndex != -1 {
            info = torrent_item_info(Int32(torrentIndex), Int32(fileIndex))
        } else {
            info = ContentItemInfo()
        }
        self.torrentIndex = torrentIndex
    }

    func fetchInfo() {
        if ViewController.get() != nil {
            if children == nil {
                info = torrent_item_info(Int32(torrentIndex), Int32(fileIndex))
            }
        }
    }
}
