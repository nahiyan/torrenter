//
//  AppDelegate.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/16/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }

    func applicationDidFinishLaunching(_: Notification) {
        // Load GeoIP database
        let db = Bundle.main.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "database")
        if db != nil {
            load_geo_ip_database(db!.path)
        }
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
        terminate()
    }

    @objc static func addTorrentFromMagnetUri() {
        let vc = ViewController.get()

        // Abort if View Controller instance doesn't exist
        if vc == nil {
            return
        }

        let savePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath

        // Let the user enter a Magnet URI
        let magnetUriWindowController = WindowController.shared!.storyboard!.instantiateController(withIdentifier: "magnetUriWindowController") as! NSWindowController
        let magnetUriWindow: NSWindow = magnetUriWindowController.window!

        NSApplication.shared.mainWindow!.beginSheet(magnetUriWindow, completionHandler: { (response: NSApplication.ModalResponse) -> Void in
            if response == .OK {
                let magnetUri: String = (magnetUriWindow.contentViewController as! MagnetUriViewController).magnetUriTextArea.string

                if magnetUri.count >= 1 {
                    let existingTorrentIndex = get_torrent_from_magnet_uri(magnetUri)
                    if existingTorrentIndex == 0 {
                        // Initiate the torrent
                        torrent_initiate_magnet_uri(magnetUri, savePath, false)

                        // Add torrent to the table
                        let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                        vc!.torrents.addObject(torrent)

                        vc!.torrentsTable.reload()
                    } else {
                        askToAddExtraTrackers(magnetUri: magnetUri, index: existingTorrentIndex)
                    }
                }
            }
        })
    }

    @objc static func addTorrentFromFile() {
        let vc = ViewController.get()

        // Abort if View Controller instance doesn't exist
        if vc == nil {
            return
        }

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

                    let existingTorrentIndex = get_torrent_from_file(loadPath)
                    if existingTorrentIndex == 0 {
                        // For now, it's the downloads folder
                        let savePath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath

                        // Initiate the torrent
                        torrent_initiate(loadPath, savePath, false)

                        // Add torrent to the table
                        let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                        vc!.torrents.addObject(torrent)

                        vc!.torrentsTable.reload()
                    } else {
                        askToAddExtraTrackers(filePath: loadPath, index: existingTorrentIndex)
                    }
                }
            }
        })
    }

    // Show alert for duplicate torrent
    private static func askToAddExtraTrackers(magnetUri: String, index: Int32) {
        if askToAddExtraTrackers() {
            add_extra_trackers_from_magnet_uri(magnetUri, index)
        }
    }

    private static func askToAddExtraTrackers(filePath: String, index: Int32) {
        if askToAddExtraTrackers() {
            add_extra_trackers_from_file(filePath, index)
        }
    }

    private static func askToAddExtraTrackers() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Torrent already exists. Want to add its trackers?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            return true
        }

        return false
    }
}
