//
//  Tracker.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/8/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Foundation

class Tracker: NSObject {
    let index: Int
    var info: TrackerInfo

    init(_ index: Int) {
        self.index = index
        info = torrent_tracker_info(Int32(index))
    }

    func fetchInfo() {
        info = torrent_tracker_info(Int32(index))
    }

    @objc var url: String {
        return String(cString: info.url)
    }

    @objc var tier: String {
        return String(format: "%d", Int(info.tier))
    }

    @objc var status: String {
        if info.is_updating {
            return "Updating"
        } else if info.is_working {
            return "Working"
        } else {
            return "Not working"
        }
    }

    @objc var peers: String {
        return String(format: "%d", info.seeds)
    }

    @objc var seeds: String {
        return String(format: "%d", info.peers)
    }

    @objc var downloaded: String {
        return String(format: "%d", info.downloaded)
    }

    @objc var message: String {
        return String(cString: info.message)
    }
}
