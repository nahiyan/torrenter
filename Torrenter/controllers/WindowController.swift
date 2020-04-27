//
//  WindowController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/22/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    @IBOutlet var pauseResumeButton: NSButton!
    @IBOutlet var stopButton: NSButton!
    @IBOutlet var removeButton: NSButton!
    @IBOutlet var sequentialDownloadToggleButton: NSButton!

    static var _shared: WindowController?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        WindowController._shared = self
    }

    static var shared: WindowController? {
        return _shared
    }

    @IBAction func addTorrentFromFile(_: Any?) {
        AppDelegate.addTorrentFromFile()
    }

    @IBAction func addTorrentFromMagnetUri(_: Any?) {
        AppDelegate.addTorrentFromMagnetUri()
    }

    @IBAction func pauseResumeToggle(_: Any) {
        let viewController: ViewController = window!.contentViewController as! ViewController
        let selectedRow: Int = viewController.torrentsTable.selectedRow
        let torrents: [Torrent] = viewController.torrents.arrangedObjects as! [Torrent]

        if selectedRow != -1 {
            let torrent: Torrent = torrents[selectedRow]

            if torrent.isPaused {
                torrent.resume()
            } else {
                torrent.pause()
            }
        }
    }

    @IBAction func remove(_: Any) {
        let viewController: ViewController = window!.contentViewController as! ViewController
        let selectedRow: Int = viewController.torrentsTable.selectedRow
        let torrents: [Torrent] = viewController.torrents.arrangedObjects as! [Torrent]

        if selectedRow != -1 {
            let torrent: Torrent = torrents[selectedRow]
            torrent.remove()
        }
    }

    @IBAction func toggleSequentialDownload(_: Any) {
        let viewController: ViewController = window!.contentViewController as! ViewController
        let selectedRow: Int = viewController.torrentsTable.selectedRow
        let torrents: [Torrent] = viewController.torrents.arrangedObjects as! [Torrent]

        if selectedRow != -1 {
            let torrent: Torrent = torrents[selectedRow]
            if torrent.isSequential {
                torrent.nonSequential()
            } else {
                torrent.sequential()
            }
        }
    }

    func deactivateButtons() {
        pauseResumeButton.isEnabled = false
        removeButton.isEnabled = false
        sequentialDownloadToggleButton.isEnabled = false

        pauseResumeButton.image = NSImage(named: "play")
        sequentialDownloadToggleButton.image = NSImage(named: "sort_ascend")
    }
}
