//
//  ViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/16/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    

    @IBOutlet weak var torrentsList: NSTableView!
    @IBOutlet weak var torrentNameColumn: NSTableColumn!
    @IBOutlet weak var tableProgressColumn: NSTableColumn!
    @IBOutlet weak var tableSeedsColumn: NSTableColumn!
    @IBOutlet weak var tablePeersColumn: NSTableColumn!
    @IBOutlet weak var tableDownloadRateColumn: NSTableColumn!
    @IBOutlet weak var tableUploadRateColumn: NSTableColumn!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        torrentsList.dataSource = self
        
        // refresh the data periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.torrentsList.reloadData()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}

// Torrents List
extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return Int(torrent_count());
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let torrent: Torrent = torrent_get(Int32(row))
        
        // value of the cell
        var value: String = ""
        switch (tableColumn?.title) {
        case "Name":
            value = String(cString: torrent.name)
        case "Progress":
            if torrent.is_seeding {
                value = "Seeding"
            } else if torrent.is_finished {
                value = "Done"
            } else {
                value = String(format: "%.1f%%", torrent.progress * 100)
            }
        case "Seeds":
            value = String(format:"%d / %d", torrent.num_seeds, torrent.list_seeds)
        case "Peers":
            value = String(format:"%d / %d", torrent.num_peers, torrent.list_peers)
        case "Download Rate":
            let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(torrent.download_rate))
            
            if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
                value = String(format:"%.2f %@", dataTransferRate.value, dataTransferRate.unit)
            } else {
                value = String(format:"%.0f %@", dataTransferRate.value, dataTransferRate.unit)
            }
        case "Upload Rate":
            let dataTransferRate: DataTransferRate = UnitConversion.dataTransferRate(Float(torrent.upload_rate))
            
            if dataTransferRate.unit == "MB/s" || dataTransferRate.unit == "GB/s" || dataTransferRate.unit == "TB/s" {
                value = String(format:"%.2f %@", dataTransferRate.value, dataTransferRate.unit)
            } else {
                value = String(format:"%.0f %@", dataTransferRate.value, dataTransferRate.unit)
            }
        default:
            value = ""
        }

        guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        cell.textField?.stringValue = value
        
        return cell
    }
    
    
}

extension NSTableView {

    func reloadDataKeepingSelection() {
        let selectedRowIndexes = self.selectedRowIndexes
        self.reloadData()
        self.selectRowIndexes(selectedRowIndexes, byExtendingSelection: true)
    }
}
