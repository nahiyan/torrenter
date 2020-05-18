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
    // lazy var persistentContainer: NSPersistentContainer = {
    //     let container = NSPersistentContainer(name: "Model")
    //     container.loadPersistentStores { _, error in
    //         if let error = error {
    //             fatalError("Unable to load persistent stores: \(error)")
    //         }
    //     }

    //     return container
    // }()

    static var shared: AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }

    func applicationDidFinishLaunching(_: Notification) {
        // Load GeoIP database
        let db = Bundle.main.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "database")
        if db != nil {
            load_geo_ip_database(db!.path)
        }

        // Make main menu functional
        for item in NSApplication.shared.menu!.items {
            switch item.title {
            case "Torrent":
                for item in item.submenu!.items {
                    switch item.title {
                    case "Add From File":
                        item.target = type(of: self)
                        item.action = #selector(AppDelegate.addTorrentFromFile)
                    case "Add From Magnet URI":
                        item.target = type(of: self)
                        item.action = #selector(AppDelegate.addTorrentFromMagnetUri)
                    case "Pause All":
                        item.target = type(of: self)
                        item.action = #selector(AppDelegate.pauseAll)
                    case "Resume All":
                        item.target = type(of: self)
                        item.action = #selector(AppDelegate.resumeAll)
                    case "Remove All":
                        item.target = type(of: self)
                        item.action = #selector(AppDelegate.removeAll)
                    default: break
                    }
                }
            default: break
            }
        }
    }

    func updateEditMenu(torrent: Torrent?) {
        for item in NSApplication.shared.menu!.items {
            switch item.title {
            case "Edit":
                for item in item.submenu!.items {
                    switch item.title {
                    case "Pause":
                        item.target = type(of: self)
                        if torrent != nil, !torrent!.isPaused {
                            item.action = #selector(AppDelegate.pauseTorrent)
                        } else {
                            item.action = nil
                        }
                    case "Resume":
                        item.target = type(of: self)
                        if torrent != nil, torrent!.isPaused {
                            item.action = #selector(AppDelegate.resumeTorrent)
                        } else {
                            item.action = nil
                        }
                    case "Delete":
                        item.target = type(of: self)
                        if torrent != nil {
                            item.action = #selector(AppDelegate.removeTorrent)
                        } else {
                            item.action = nil
                        }
                    default: break
                    }
                }
            default: break
            }
        }
    }

    @objc static func pauseTorrent() {
        ViewController.shared!.torrentsTable.pauseTorrent()
    }

    @objc static func resumeTorrent() {
        ViewController.shared!.torrentsTable.resumeTorrent()
    }

    @objc static func removeTorrent() {
        ViewController.shared!.torrentsTable.removeTorrent()
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
        terminate()
    }

    @objc static func removeAll() {
        let vc = ViewController.get()

        // Abort if View Controller instance doesn't exist
        if vc == nil {
            return
        }

        let torrents: [Torrent] = vc!.torrents.arrangedObjects as! [Torrent]
        for torrent in torrents {
            torrent.remove()
        }
    }

    @objc static func pauseAll() {
        let vc = ViewController.get()

        // Abort if View Controller instance doesn't exist
        if vc == nil {
            return
        }

        let torrents: [Torrent] = vc!.torrents.arrangedObjects as! [Torrent]
        for torrent in torrents {
            if !torrent.isPaused {
                torrent.pause()
            }
        }
    }

    @objc static func resumeAll() {
        let vc = ViewController.get()

        // Abort if View Controller instance doesn't exist
        if vc == nil {
            return
        }

        let torrents: [Torrent] = vc!.torrents.arrangedObjects as! [Torrent]
        for torrent in torrents {
            if torrent.isPaused {
                torrent.resume()
            }
        }
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
                    if !torrent_exists_from_magnet_uri(magnetUri) {
                        // Initiate the torrent
                        torrent_initiate_magnet_uri(magnetUri, savePath, false)

                        // Add torrent to the table
                        let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                        vc!.torrents.addObject(torrent)

                        vc!.torrentsTable.reload()
                    } else {
                        print("Torrent already exists")
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

                    if !torrent_exists(loadPath) {
                        // For now, it's the downloads folder
                        let savePath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath

                        // Initiate the torrent
                        torrent_initiate(loadPath, savePath, false)

                        // Add torrent to the table
                        let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                        vc!.torrents.addObject(torrent)

                        vc!.torrentsTable.reload()
                    } else {
                        print("Torrent already exists")
                    }
                }
            }
        })
    }
}
