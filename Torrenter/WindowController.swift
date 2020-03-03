//
//  WindowController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/22/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func addTorrent (_ sender: Any?) -> Void {
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
                    // For now, it's the downloads folder
                    let savePath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath
                    
                    // Initiate the torrent
                    torrent_initiate(loadPath, savePath)
                    
                    // Add torrent to the table
                    let torrent: Torrent = Torrent()
                    viewController.torrents.addObject(torrent)
                    
                    // Save torrent initializer using CoreData
                    TorrentInitializer.insert(container: viewController.container, loadPath: loadPath, savePath: savePath)

                    viewController.reloadTorrentsTable()
                }
            }
        })
    }

}
