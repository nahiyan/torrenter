//
//  TorrentsTable.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/17/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class TorrentsTable: NSTableView {
    var torrent: Torrent?

    override func willOpenMenu(_ menu: NSMenu, with _: NSEvent) {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        let torrentIndex: Int = viewController.torrentsTable.clickedRow
        if torrentIndex != -1 {
            torrent = (viewController.torrents.arrangedObjects as! [Torrent])[torrentIndex]
            let contextMenu: NSMenu = viewController.contextMenu

            // Play/pause item
            let playPauseItem: NSMenuItem? = contextMenu.item(at: 0)
            if torrent!.isPaused {
                playPauseItem?.title = "Resume"
                playPauseItem?.action = #selector(resumeTorrent)
            } else {
                playPauseItem?.title = "Pause"
                playPauseItem?.action = #selector(pauseTorrent)
            }
        }
    }

    @objc func pauseTorrent() {
        torrent!.pause()
    }

    @objc func resumeTorrent() {
        torrent!.resume()
    }
}
