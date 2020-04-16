//
//  TorrentFile.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/9/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import AppKit
import Foundation

class TorrentContentItem: NSObject {
    @objc dynamic let name: String
    @objc dynamic var state: NSControl.StateValue {
        get {
            if children != nil { // Directory
                var offCount: Int = 0

                for child in children! {
                    if child.state == NSControl.StateValue.mixed {
                        return NSControl.StateValue.mixed
                    } else if child.state == NSControl.StateValue.off {
                        offCount += 1
                    }
                }

                if offCount == children!.count {
                    return NSControl.StateValue.off
                } else if offCount == 0 {
                    return NSControl.StateValue.on
                } else {
                    return NSControl.StateValue.mixed
                }
            } else { // File
                if info.priority == 0 {
                    return NSControl.StateValue.off
                } else {
                    return NSControl.StateValue.on
                }
            }
        }
        set {
            let priority: Int32
            if newValue == NSControl.StateValue.on || newValue == NSControl.StateValue.mixed {
                priority = 4
            } else {
                priority = 0
            }

            // print(newValue == NSControl.StateValue.mixed, priority)

            // Set the priority
            if children == nil {
                torrent_file_priority(Int32(torrentIndex), Int32(fileIndex), priority)
            } else {
                for child in children! {
                    if priority == 4 {
                        child.state = NSControl.StateValue.on
                    } else {
                        child.state = NSControl.StateValue.off
                    }
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
        let data: Data = UnitConversion.dataAuto(info.size)

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    let torrentIndex: Int

    var progress: String {
        if children == nil {
            if info.size != 0 {
                return String(format: "%.1f%%", (info.progress / info.size) * 100)
            } else {
                return ""
            }
        } else {
            return ""
        }
    }

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
