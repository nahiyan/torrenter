//
//  WindowController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/22/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    @IBOutlet weak var pauseResumeButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func addTorrentFromFile (_ sender: Any?) -> Void {
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
                    torrent_initiate(loadPath, savePath, false)
                    
                    // Save torrent initializer using CoreData
                    let objectID: NSManagedObjectID = TorrentInitializer.insert(container: viewController.container, loadPath: loadPath, savePath: savePath)
                    
                    // Add torrent to the table
                    let torrent: Torrent = Torrent(objectID)
                    viewController.torrents.addObject(torrent)

                    viewController.reloadTorrentsTable()
                }
            }
        })
    }
    
    @IBAction func addTorrentFromMagnetUri (_ sender: Any?) -> Void {
        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController
        let savePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").relativePath
        
        // Let the user enter a Magnet URI
        let magnetUriWindowController = self.storyboard!.instantiateController(withIdentifier: "magnetUriWindowController") as! NSWindowController
        let magnetUriWindow: NSWindow = magnetUriWindowController.window!
        
        NSApplication.shared.mainWindow!.beginSheet(magnetUriWindow, completionHandler: { (result) -> Void in
            let magnetUri: String = (magnetUriWindow.contentViewController as! MagnetUriViewController).magnetUriTextField.stringValue
            
            // Initiate the torrent
            torrent_initiate_magnet_uri(magnetUri, savePath, false)
            
            // Save torrent initializer using CoreData
            let objectID: NSManagedObjectID = TorrentInitializer.insert(container: viewController.container, magnetUri: magnetUri, savePath: savePath)
            
            // Add torrent to the table
            let torrent: Torrent = Torrent(objectID)
            viewController.torrents.addObject(torrent)

            viewController.reloadTorrentsTable()
        })
    }

    @IBAction func pauseResumeToggle(_ sender: Any) {
        let viewController: ViewController = window!.contentViewController as! ViewController
        let selectedRow: Int = viewController.torrentsTable.selectedRow
        let torrents: [Torrent] = viewController.torrents.arrangedObjects as! [Torrent]
        
        if selectedRow != -1 {
            let torrent: Torrent = torrents[selectedRow]
            
            if torrent.isPaused {
                torrent.resume()
                pauseResumeButton.image = NSImage(named: "pause")
                
                TorrentInitializer.get(viewController.container, torrent.id)?.status = "default"
            } else {
                torrent.pause()
                pauseResumeButton.image = NSImage(named: "play")
                
                TorrentInitializer.get(viewController.container, torrent.id)?.status = "paused"
            }
            
            do {
                try viewController.container.viewContext.save()
            } catch {
                print("Failed to save CoreData context")
            }
        }
    }
    
    @IBAction func stop(_ sender: Any) {
        
    }
    
    
    @IBAction func remove(_ sender: Any) {
        let viewController: ViewController = window!.contentViewController as! ViewController
        let selectedRow: Int = viewController.torrentsTable.selectedRow
        let torrents: [Torrent] = viewController.torrents.arrangedObjects as! [Torrent]
        
        if selectedRow != -1 {
            let torrent: Torrent = torrents[selectedRow]
            
            // Remove CoreData entry
            let torrentInitializer: TorrentInitializer = TorrentInitializer.get(viewController.container, torrent.id)!
            viewController.container.viewContext.delete(torrentInitializer)
            
            // Remove torrent from array
            viewController.torrents.removeObject(torrent)
            
            do {
                try viewController.container.viewContext.save()
            } catch {
                print("Failed to save CoreData context")
            }
        }
    }
}
