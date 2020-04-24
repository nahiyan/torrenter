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

    required init?(coder: NSCoder) {
        torrent = nil
        super.init(coder: coder)

        menu = NSMenu()
        menu!.addItem(withTitle: "Pause", action: nil, keyEquivalent: "")
        menu!.addItem(withTitle: "Remove", action: nil, keyEquivalent: "")
        menu!.addItem(NSMenuItem.separator())
        menu!.addItem(withTitle: "Limit Download Rate", action: nil, keyEquivalent: "")
        menu!.addItem(withTitle: "Limit Upload Rate", action: nil, keyEquivalent: "")
        menu!.addItem(NSMenuItem.separator())
        menu!.addItem(withTitle: "Download in Sequential Order", action: nil, keyEquivalent: "")
        menu!.addItem(NSMenuItem.separator())
        menu!.addItem(withTitle: "Force Recheck", action: nil, keyEquivalent: "")
        menu!.addItem(withTitle: "Force Reannounce", action: nil, keyEquivalent: "")
        menu!.addItem(NSMenuItem.separator())
        menu!.addItem(withTitle: "Open Destination Directory", action: nil, keyEquivalent: "")
    }

    override func willOpenMenu(_ menu: NSMenu, with _: NSEvent) {
        let vc: ViewController? = ViewController.get()

        if vc == nil {
            return
        }

        let torrentIndex: Int = vc!.torrentsTable.clickedRow
        if torrentIndex != -1 {
            torrent = (vc!.torrents.arrangedObjects as! [Torrent])[torrentIndex]
            let contextMenu: NSMenu = self.menu!

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
            let limitDownloadRateItem: NSMenuItem? = contextMenu.item(at: 3)
            limitDownloadRateItem?.action = #selector(limitDownloadRate)

            // Limit Upload Rate -> 4
            let limitUploadRateItem: NSMenuItem? = contextMenu.item(at: 4)
            limitUploadRateItem?.action = #selector(limitUploadRate)

            // Separator -> 5

            // Download in sequential order -> 6
            let downloadInSequentialOrderItem: NSMenuItem? = contextMenu.item(at: 6)

            if torrent!.isSequential {
                downloadInSequentialOrderItem?.state = .on
            } else {
                downloadInSequentialOrderItem?.state = .off
            }
            downloadInSequentialOrderItem?.action = #selector(downloadInSequentialOrder)

            // Separator -> 7

            // Force Recheck -> 8
            let forceRecheckItem: NSMenuItem? = contextMenu.item(at: 8)
            forceRecheckItem?.action = #selector(forceRecheckTorrent)

            // Force Reannounce -> 9
            let forceReannounceItem: NSMenuItem? = contextMenu.item(at: 9)
            forceReannounceItem?.action = #selector(forceReannounceTorrent)

            // Separator -> 10

            // Open Destination Directory -> 11
            let openDestDirItem: NSMenuItem? = contextMenu.item(at: 11)
            openDestDirItem?.action = #selector(openDestinationDirectory)
        }
    }

    func postOperation() {
        let vc: ViewController? = ViewController.get()
        vc?.updateActionButtonsAndDetailsView()
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

    @objc func openDestinationDirectory() {
        let pathCString: UnsafePointer<CChar>? = torrent_get_first_root_content_item_path(Int32(torrent!.index))

        if pathCString != nil {
            let path: String = String(cString: pathCString!)
            free(UnsafeMutableRawPointer(mutating: pathCString))

            let url: URL = URL(fileURLWithPath: path)

            // Open file with default application
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc func limitRate(isDownloadRate: Bool) {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        let torrent: Torrent = (viewController.torrents.arrangedObjects as! [Torrent])[clickedRow]

        let storyboard: NSStoryboard = NSApplication.shared.mainWindow!.windowController!.storyboard!
        let uploadRateLimitWindowController = storyboard.instantiateController(withIdentifier: "rateLimitWindowController") as! NSWindowController
        let rateLimitWindow: NSWindow = uploadRateLimitWindowController.window!

        // Set the rate limit of the view controller
        let rateLimitViewController: RateLimitViewController = (rateLimitWindow.contentViewController as! RateLimitViewController)
        if isDownloadRate {
            rateLimitViewController.limit = torrent.info.download_limit
        } else {
            rateLimitViewController.limit = torrent.info.upload_limit
        }

        NSApplication.shared.mainWindow!.beginSheet(rateLimitWindow, completionHandler: { (response: NSApplication.ModalResponse) -> Void in
            if response == .OK {
                let rateLimit: Float = (rateLimitWindow.contentViewController as! RateLimitViewController).rateLimit.floatValue
                let rateLimitUnit: String = (rateLimitWindow.contentViewController as! RateLimitViewController).rateLimitUnit.selectedItem!.title
                let isUnlimited: Bool = (rateLimitWindow.contentViewController as! RateLimitViewController).isUnlimited.state == .on

                let rateLimitUnitModified: String = String(rateLimitUnit[..<rateLimitUnit.lastIndex(of: "/")!])
                let rateLimitInBytes: Int = UnitConversion.getBytes(Data(rateLimit, rateLimitUnitModified))

                if isUnlimited {
                    if isDownloadRate {
                        torrent_set_download_rate_limit(Int32(torrent.index), -1)
                    } else {
                        torrent_set_upload_rate_limit(Int32(torrent.index), -1)
                    }
                } else {
                    if isDownloadRate {
                        torrent_set_download_rate_limit(Int32(torrent.index), Int32(rateLimitInBytes))
                    } else {
                        torrent_set_upload_rate_limit(Int32(torrent.index), Int32(rateLimitInBytes))
                    }
                }
            }
        })
    }

    @objc func limitDownloadRate() {
        limitRate(isDownloadRate: true)
    }

    @objc func limitUploadRate() {
        limitRate(isDownloadRate: false)
    }
}
