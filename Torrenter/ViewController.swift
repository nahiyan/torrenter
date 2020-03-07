//
//  ViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/16/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet var torrents: NSArrayController!
    @IBOutlet weak var torrentsTable: NSTableView!
    var container: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let delegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        self.container = delegate.persistentContainer
        
        guard container != nil else {
            fatalError("This view needs a persistent container.")
        }
        
        // refresh the data periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.reloadTorrentsTable()
        }
        
        // Load all the torrents from CoreData
        let torrentInitializers: [TorrentInitializer] = TorrentInitializer.getAll(container)
        for torrentInitializer in torrentInitializers {
            let savePath: String = torrentInitializer.savePath
            
            // Add torrent to list
            let torrent: Torrent = Torrent(torrentInitializer.objectID)
            torrents.addObject(torrent)
            
            // Indicate if the torrent should be paused or not
            let paused: Bool
            if torrentInitializer.status == "paused" {
                paused = true
            } else {
                paused = false
            }

            // Initiate torrent
            if let loadPath: String = torrentInitializer.loadPath {
                torrent_initiate(loadPath, savePath, paused)
            } else {
                if let magnetUri: String = torrentInitializer.magnetUri {
                    torrent_initiate_magnet_uri(magnetUri, savePath, paused)
                } else {
                    continue
                }
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func tableClicked(_ sender: Any) {
        let windowController: WindowController = NSApplication.shared.mainWindow!.windowController as! WindowController
        let pauseResumeButton: NSButton = windowController.pauseResumeButton
        let stopButton: NSButton = windowController.stopButton
        let removeButton: NSButton = windowController.removeButton
        
        if (torrentsTable.selectedRow != -1) {
            let torrent: Torrent = (torrents.arrangedObjects as! [Torrent])[torrentsTable.selectedRow]
            
            pauseResumeButton.isEnabled = true
            if torrent.isPaused {
                pauseResumeButton.image = NSImage(named: "play")
            } else {
                pauseResumeButton.image = NSImage(named: "pause")
            }
            
            
            if torrent.isFinished && !torrent.isSeeding {
                stopButton.isEnabled = false
            } else {
                stopButton.isEnabled = true
            }
            
            removeButton.isEnabled = true
        } else {
            pauseResumeButton.isEnabled = false
            stopButton.isEnabled = false
            removeButton.isEnabled = false
            
            pauseResumeButton.image = NSImage(named: "play")
        }
    }
}

extension ViewController {
    func reloadTorrentsTable() -> Void {
        let selectedRow: Int = torrentsTable.selectedRow
        torrentsTable.reloadData()
        torrentsTable.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    }
}
