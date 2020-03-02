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
            
//            let selectedRow: Int = self.torrentsTable.selectedRow
//            let t:[Torrent] = self.torrents.arrangedObjects as! [Torrent]
//
//            if self.torrentsTable.isRowSelected(selectedRow) {
//                print(String(cString: t[selectedRow].getInfo().name))
//            } else {
//                print("No row selected")
//            }
        }
        
        let torrent: Torrent = Torrent()
        torrent.filePath = "fuck"
        torrent.savePath = "suck"
        container.viewContext.insert(torrent)
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

// Manage Table View
//extension ViewController: NSTableViewDelegate {
//    func tableViewSelectionDidChange(_ notification: Notification) {
//
//    }
//}
