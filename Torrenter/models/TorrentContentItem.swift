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
    var _state: NSControl.StateValue
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
                if _state == NSControl.StateValue.off {
                    return NSControl.StateValue.off
                } else {
                    return NSControl.StateValue.on
                }
            }
        }
        set {
            let vc: ViewController? = ViewController.get()
            if vc != nil {
                vc!.torrentDetails.canRefresh = false
            }

            let priority: Int32
            if newValue == NSControl.StateValue.on || newValue == NSControl.StateValue.mixed {
                priority = 4
            } else {
                priority = 0
            }

            // Set the priority
            if children == nil {
                torrent_file_priority(Int32(torrentIndex), Int32(fileIndex), priority)
            } else {
                for child in children! {
                    if priority == 0 {
                        child.state = NSControl.StateValue.off
                        child.info.priority = 0
                    } else {
                        child.state = NSControl.StateValue.on
                        child.info.priority = 4
                    }
                }
            }

            // Update the state
            if priority == 0 {
                _state = NSControl.StateValue.off
            } else {
                _state = NSControl.StateValue.on
            }
            info.priority = priority

            // Reload the table to reflect the changes
            if vc != nil {
                vc!.torrentDetails.reloadContentTable()

                letRefreshAfterPriorityUpdates(expectedPriority: priority)
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
        if info.size != 0 {
            return String(format: "%.1f%%", (info.progress / info.size) * 100)
        } else {
            return "N/A"
        }
    }

    var remaining: String {
        let data: Data = UnitConversion.dataAuto(info.size - info.progress)

        if data.unit == "MB" || data.unit == "GB" || data.unit == "TB" {
            return String(format: "%.2f %@", data.value, data.unit)
        } else {
            return String(format: "%.0f %@", data.value, data.unit)
        }
    }

    var path: String {
        return String(cString: info.path)
    }

    var parentPath: String {
        return String(cString: info.parent_path)
    }

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

        if info.priority == 0 {
            _state = NSControl.StateValue.off
        } else {
            _state = NSControl.StateValue.on
        }
    }

    func fetchInfo() {
        if ViewController.get() != nil {
            if children == nil {
                torrent_item_info_destroy(info)
                info = torrent_item_info(Int32(torrentIndex), Int32(fileIndex))
            }
        }
    }

    private static func childrenPriorityCheck(item: TorrentContentItem, priority: Int32) -> Bool {
        for child in item.children! {
            if child.info.priority != priority {
                return false
            }

            if child.children != nil {
                if !childrenPriorityCheck(item: child, priority: priority) {
                    return false
                }
            }
        }

        return true
    }

    // Let the torrent content refresh only after the expected priority is obtained
    private func letRefreshAfterPriorityUpdates(expectedPriority: Int32) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.fetchInfo()

            if expectedPriority == self.info.priority {
                // Check priorities of its children, if it has any
                var childPriorities = true
                if self.children != nil {
                    childPriorities = TorrentContentItem.childrenPriorityCheck(item: self, priority: expectedPriority)
                }

                if childPriorities {
                    let vc: ViewController? = ViewController.get()
                    if vc != nil {
                        vc!.torrentDetails.canRefresh = true
                        timer.invalidate()
                    }
                }
            }
        }
    }
}
