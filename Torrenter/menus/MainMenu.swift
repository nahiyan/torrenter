//
//  MainMenu.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 5/18/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa
class MainMenu: NSMenu, NSMenuDelegate {
    required init(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    func menuWillOpen(_ menu: NSMenu) {
        switch menu.title {
        case "Torrent":
            updateTorrentMenu()
        case "Edit":
            updateEditMenu()
        default:
            break
        }
    }

    func updateEditMenu() {
        if ViewController.shared == nil {
            return
        }
        weak var torrent: Torrent? = ViewController.shared!.torrentsTable.torrent

        for item in NSApplication.shared.menu!.items {
            switch item.title {
            case "Edit":
                for item in item.submenu!.items {
                    switch item.title {
                    case "Pause":
                        item.target = type(of: self)
                        if torrent != nil, !torrent!.isPaused {
                            item.action = #selector(MainMenu.pauseTorrent)
                        } else {
                            item.action = nil
                        }
                    case "Resume":
                        item.target = type(of: self)
                        if torrent != nil, torrent!.isPaused {
                            item.action = #selector(MainMenu.resumeTorrent)
                        } else {
                            item.action = nil
                        }
                    case "Delete":
                        item.target = type(of: self)
                        if torrent != nil {
                            item.action = #selector(MainMenu.removeTorrent)
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

    func updateTorrentMenu() {
        for item in NSApplication.shared.menu!.items {
            switch item.title {
            case "Torrent":
                for item in item.submenu!.items {
                    switch item.title {
                    case "Add From File":
                        item.target = type(of: self)
                        item.action = #selector(MainMenu.addTorrentFromFile)
                    case "Add From Magnet URI":
                        item.target = type(of: self)
                        item.action = #selector(MainMenu.addTorrentFromMagnetUri)
                    case "Pause All":
                        item.target = type(of: self)
                        item.action = #selector(MainMenu.pauseAll)
                    case "Resume All":
                        item.target = type(of: self)
                        item.action = #selector(MainMenu.resumeAll)
                    case "Remove All":
                        item.target = type(of: self)
                        item.action = #selector(MainMenu.removeAll)
                    default: break
                    }
                }
            default: break
            }
        }
    }

    @objc static func addTorrentFromFile() {
        AppDelegate.addTorrentFromFile()
    }

    @objc static func addTorrentFromMagnetUri() {
        AppDelegate.addTorrentFromMagnetUri()
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
}
