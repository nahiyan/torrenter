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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // refresh the data periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.reloadTorrentsTable()
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
        let selectedRow: Int = torrentsTable.selectedRow
        torrentsTable.reloadData()
        torrentsTable.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    }
}
