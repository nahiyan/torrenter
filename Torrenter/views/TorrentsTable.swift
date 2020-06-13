//
//  TorrentsTable.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/17/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class TorrentsTable: NSTableView {
    var selectedTorrent: Torrent? {
        if selectedRow != -1, ViewController.shared != nil {
            return (ViewController.shared!.torrents.arrangedObjects as! [Torrent])[selectedRow]
        } else {
            return nil
        }
    }

    var clickedTorrent: Torrent? {
        if clickedRow != -1, ViewController.shared != nil {
            return (ViewController.shared!.torrents.arrangedObjects as! [Torrent])[clickedRow]
        } else {
            return nil
        }
    }

    required init?(coder: NSCoder) {
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

    override func willOpenMenu(_: NSMenu, with _: NSEvent) {
        let vc: ViewController? = ViewController.get()

        if vc == nil {
            return
        }

        if clickedRow != -1 {
            let contextMenu: NSMenu = menu!

            // Play/pause item
            let playPauseItem: NSMenuItem? = contextMenu.item(at: 0)
            if clickedTorrent!.isPaused {
                playPauseItem?.title = "Resume"
                playPauseItem?.action = #selector(resumeTorrent)
            } else {
                playPauseItem?.title = "Pause"
                playPauseItem?.action = #selector(pauseTorrent)
            }

            // Remove item
            let removeItem: NSMenuItem? = contextMenu.item(withTitle: "Remove")
            removeItem?.action = #selector(removeTorrent)

            // Separator

            // Limit Download Rate
            let limitDownloadRateItem: NSMenuItem? = contextMenu.item(withTitle: "Limit Download Rate")
            limitDownloadRateItem?.action = #selector(limitDownloadRate)

            // Limit Upload Rate
            let limitUploadRateItem: NSMenuItem? = contextMenu.item(withTitle: "Limit Upload Rate")
            limitUploadRateItem?.action = #selector(limitUploadRate)

            // Separator

            // Download in sequential order
            let downloadInSequentialOrderItem: NSMenuItem? = contextMenu.item(withTitle: "Download in Sequential Order")

            if clickedTorrent!.isSequential {
                downloadInSequentialOrderItem?.state = .on
            } else {
                downloadInSequentialOrderItem?.state = .off
            }
            downloadInSequentialOrderItem?.action = #selector(downloadInSequentialOrder)

            // Separator

            // Force Recheck
            let forceRecheckItem: NSMenuItem? = contextMenu.item(withTitle: "Force Recheck")
            forceRecheckItem?.action = #selector(forceRecheckTorrent)

            // Force Reannounce
            let forceReannounceItem: NSMenuItem? = contextMenu.item(withTitle: "Force Reannounce")
            forceReannounceItem?.action = #selector(forceReannounceTorrent)

            // Separator

            // Open Destination Directory
            let openDestDirItem: NSMenuItem? = contextMenu.item(withTitle: "Open Destination Directory")
            openDestDirItem?.action = #selector(openDestinationDirectory)
        }
    }

    func postOperation() {
        let vc: ViewController? = ViewController.get()
        vc?.updateActionButtonsAndDetailsView()
    }

    @objc func pauseTorrent() {
        clickedTorrent!.pause()
        postOperation()
    }

    @objc func resumeTorrent() {
        clickedTorrent!.resume()
        postOperation()
    }

    @objc func removeTorrent() {
        clickedTorrent!.remove()
    }

    @objc func downloadInSequentialOrder() {
        if clickedTorrent!.isSequential {
            clickedTorrent!.nonSequential()
        } else {
            clickedTorrent!.sequential()
        }
    }

    @objc func forceRecheckTorrent() {
        clickedTorrent!.forceRecheck()
    }

    @objc func forceReannounceTorrent() {
        clickedTorrent!.forceReannounce()
    }

    @objc func openDestinationDirectory() {
        let pathCString: UnsafePointer<CChar>? = torrent_get_first_root_content_item_path(Int32(clickedTorrent!.index))

        if pathCString != nil {
            let path: String = String(cString: pathCString!)
            free(UnsafeMutableRawPointer(mutating: pathCString))

            let url: URL = URL(fileURLWithPath: path)

            // Open file with default application
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc func limitRate(isDownloadRate: Bool) {
        let storyboard: NSStoryboard = NSApplication.shared.mainWindow!.windowController!.storyboard!
        let rateLimitWindowController = storyboard.instantiateController(withIdentifier: "rateLimitWindowController") as! NSWindowController
        let rateLimitWindow: NSWindow = rateLimitWindowController.window!

        // Set the rate limit of the view controller
        let rateLimitViewController: RateLimitViewController = (rateLimitWindow.contentViewController as! RateLimitViewController)
        if isDownloadRate {
            rateLimitViewController.limit = clickedTorrent!.info.download_limit
            rateLimitViewController.rateLimitLabel.stringValue = "Download Rate Limit:"
        } else {
            rateLimitViewController.limit = clickedTorrent!.info.upload_limit
            rateLimitViewController.rateLimitLabel.stringValue = "Upload Rate Limit:"
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
                        torrent_set_download_rate_limit(Int32(self.clickedTorrent!.index), -1)
                    } else {
                        torrent_set_upload_rate_limit(Int32(self.clickedTorrent!.index), -1)
                    }
                } else {
                    if isDownloadRate {
                        torrent_set_download_rate_limit(Int32(self.clickedTorrent!.index), Int32(rateLimitInBytes))
                    } else {
                        torrent_set_upload_rate_limit(Int32(self.clickedTorrent!.index), Int32(rateLimitInBytes))
                    }
                }
            }
        })
    }

    func reload() {
        // Reload table data and retain row selection
        let _selectedRow = selectedRow

        let vc = ViewController.get()
        if vc != nil {
            vc!.torrents.rearrangeObjects()

            reloadData()
            selectRowIndexes(IndexSet(integer: _selectedRow), byExtendingSelection: false)

            // Refresh progress bars
            vc!.refreshProgressBars()
        }
    }

    @objc func limitDownloadRate() {
        limitRate(isDownloadRate: true)
    }

    @objc func limitUploadRate() {
        limitRate(isDownloadRate: false)
    }
}
