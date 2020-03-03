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
        
        // Load all the torrents
        let torrentInitializers: [TorrentInitializer] = TorrentInitializer.getAll(container)
        torrentInitializers.forEach{ torrentInitializer in
            let loadPath: String = torrentInitializer.loadPath
            let savePath: String = torrentInitializer.savePath
            let torrentIndex: Int = Int(torrent_count())
            
            torrent_initiate(loadPath, savePath)
            torrents.addObject(Torrent(torrentIndex))
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}

extension ViewController {
    func reloadTorrentsTable() -> Void {
        let selectedRow: Int = self.torrentsTable.selectedRow
        torrentsTable.reloadData()
        torrentsTable.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    }
}
