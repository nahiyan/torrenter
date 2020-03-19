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

            // Play/pause item -> 0
            let playPauseItem: NSMenuItem? = contextMenu.item(at: 0)
            if torrent!.isPaused {
                playPauseItem?.title = "Resume"
                playPauseItem?.action = #selector(resumeTorrent)
            } else {
                playPauseItem?.title = "Pause"
                playPauseItem?.action = #selector(pauseTorrent)
            }

            // Remove item -> 1
            let removeItem: NSMenuItem? = contextMenu.item(at: 1)
            removeItem?.action = #selector(removeTorrent)

            // Separator -> 2
            // Limit Download Rate -> 3
            // Limit Upload Rate -> 4
            // Limit Share Ratio -> 5
            // Separator -> 6

            // Download in sequential order -> 7
            let downloadInSequentialOrderItem: NSMenuItem? = contextMenu.item(at: 7)

            if torrent!.isSequential {
                downloadInSequentialOrderItem?.state = .on
            } else {
                downloadInSequentialOrderItem?.state = .off
            }
            downloadInSequentialOrderItem?.action = #selector(downloadInSequentialOrder)

            // Separator -> 8

            // Force Recheck -> 9
            let forceRecheckItem: NSMenuItem? = contextMenu.item(at: 9)
            forceRecheckItem?.action = #selector(forceRecheckTorrent)

            // Force Reannounce -> 10
            let forceReannounceItem: NSMenuItem? = contextMenu.item(at: 10)
            forceReannounceItem?.action = #selector(forceReannounceTorrent)

            // Separator -> 11

            // Open Destination Directory -> 12
            let openDestDirItem: NSMenuItem? = contextMenu.item(at: 12)
            openDestDirItem?.action = #selector(openDestDir)
        }
    }

    func postOperation() {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController
        viewController.updateActionButtonsAndDetailsView()
    }

    @objc func pauseTorrent() {
        torrent!.pause()
        postOperation()
    }

    @objc func resumeTorrent() {
        torrent!.resume()
        postOperation()
    }

    @objc func removeTorrent() {
        torrent!.remove()
    }

    @objc func downloadInSequentialOrder() {
        if torrent!.isSequential {
            torrent!.nonSequential()
        } else {
            torrent!.sequential()
        }
    }

    @objc func forceRecheckTorrent() {
        torrent!.forceRecheck()
    }

    @objc func forceReannounceTorrent() {
        torrent!.forceReannounce()
    }

    @objc func openDestDir() {
        let path: URL? = URL(fileURLWithPath: torrent!.savePath, isDirectory: true)
        if path != nil {
            print(NSWorkspace.shared.activateFileViewerSelecting([path!]))
        }
    }
}
