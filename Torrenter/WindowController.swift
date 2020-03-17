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

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    @IBAction func addTorrentFromFile(_: Any?) {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        // Let the user load a torrent file
        let fileManager = FileManager.default
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["torrent"]
        panel.allowsMultipleSelection = false
        panel.begin(completionHandler: { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if panel.urls.count == 1 {
                    let loadPath = panel.urls[0].relativePath

                    if !torrent_exists(loadPath) {
                        // For now, it's the downloads folder
                        let savePath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath

                        // Initiate the torrent
                        torrent_initiate(loadPath, savePath, false)

                        // Add torrent to the table
                        let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                        viewController.torrents.addObject(torrent)

                        viewController.reloadTorrentsTable()
                    } else {
                        print("Torrent already exists")
                    }
                }
            }
        })
    }

    @IBAction func addTorrentFromMagnetUri(_: Any?) {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController
        let savePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath

        // Let the user enter a Magnet URI
        let magnetUriWindowController = storyboard!.instantiateController(withIdentifier: "magnetUriWindowController") as! NSWindowController
        let magnetUriWindow: NSWindow = magnetUriWindowController.window!

        NSApplication.shared.mainWindow!.beginSheet(magnetUriWindow, completionHandler: { (_) -> Void in
            let magnetUri: String = (magnetUriWindow.contentViewController as! MagnetUriViewController).magnetUriTextArea.string
            if !torrent_exists_from_magnet_uri(magnetUri) {
                // Initiate the torrent
                torrent_initiate_magnet_uri(magnetUri, savePath, false)

                // Add torrent to the table
                let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                viewController.torrents.addObject(torrent)

                viewController.reloadTorrentsTable()
            } else {
                print("Torrent already exists")
            }
        })
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

    @IBAction func stop(_: Any) {}

    @IBAction func remove(_: Any) {
        let viewController: ViewController = window!.contentViewController as! ViewController
        let selectedRow: Int = viewController.torrentsTable.selectedRow
        let torrents: [Torrent] = viewController.torrents.arrangedObjects as! [Torrent]

        if selectedRow != -1 {
            let torrent: Torrent = torrents[selectedRow]
            torrent.remove()
        }
    }

    func deactivateButtons() {
        pauseResumeButton.isEnabled = false
        stopButton.isEnabled = false
        removeButton.isEnabled = false

        pauseResumeButton.image = NSImage(named: "play")
    }
}
