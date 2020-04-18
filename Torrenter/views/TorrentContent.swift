//
//  TorrentContent.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/9/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class TorrentContent: NSOutlineView, NSOutlineViewDelegate, NSOutlineViewDataSource {
    var content: [TorrentContentItem]
    var vc: ViewController? {
        ViewController.get()
    }

    required init?(coder: NSCoder) {
        content = []

        super.init(coder: coder)

        delegate = self
        dataSource = self

        // context menu
        menu = NSMenu()
        menu!.addItem(withTitle: "Open", action: #selector(openFile), keyEquivalent: "")
        menu!.addItem(withTitle: "Open Containing Directory", action: #selector(openContainingDirectory), keyEquivalent: "")
        menu!.addItem(withTitle: "Priority", action: nil, keyEquivalent: "")

        let priorityMenu: NSMenu = NSMenu()
        priorityMenu.addItem(withTitle: "Don't download", action: #selector(setPriorityDonotDownload), keyEquivalent: "")
        priorityMenu.addItem(withTitle: "Low", action: #selector(setPriorityLow), keyEquivalent: "")
        priorityMenu.addItem(withTitle: "Normal", action: #selector(setPriorityNormal), keyEquivalent: "")
        priorityMenu.addItem(withTitle: "High", action: #selector(setPriorityHigh), keyEquivalent: "")

        menu!.setSubmenu(priorityMenu, for: menu!.item(at: 2)!)
    }

    @objc func openFile() {
        if vc == nil {
            return
        }

        let clickedRow = vc!.torrentContent.clickedRow

        if clickedRow != -1 {
            let item: TorrentContentItem = vc!.torrentContent.item(atRow: clickedRow) as! TorrentContentItem

            if item.children == nil {
                let url = URL(fileURLWithPath: item.path, isDirectory: false)

                // Open file with default application
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc func openContainingDirectory() {
        if vc == nil {
            return
        }

        let clickedRow = vc!.torrentContent.clickedRow

        if clickedRow != -1 {
            let item: TorrentContentItem = vc!.torrentContent.item(atRow: clickedRow) as! TorrentContentItem

            if item.children == nil {
                let url = URL(fileURLWithPath: item.parentPath, isDirectory: true)

                let configuration: NSWorkspace.OpenConfiguration = NSWorkspace.OpenConfiguration()
                configuration.promptsUserIfNeeded = true

                let finder = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder")

                // Open file with default application
                NSWorkspace.shared.open([url], withApplicationAt: finder!, configuration: configuration)
            }
        }
    }

    @objc func setPriorityDonotDownload() {
        setPriority(priority: 0)
    }

    @objc func setPriorityLow() {
        setPriority(priority: 1)
    }

    @objc func setPriorityNormal() {
        setPriority(priority: 4)
    }

    @objc func setPriorityHigh() {
        setPriority(priority: 7)
    }

    func setPriority(priority: Int32) {
        if vc == nil {
            return
        }

        let clickedRow = vc!.torrentContent.clickedRow

        if clickedRow != -1 {
            let item: TorrentContentItem = vc!.torrentContent.item(atRow: clickedRow) as! TorrentContentItem

            setPriority(item: item, priority: priority)
        }
    }

    private func setPriority(item: TorrentContentItem, priority: Int32) {
        if priority == 0 {
            item._state = NSControl.StateValue.off
        } else {
            item._state = NSControl.StateValue.on
        }

        if item.children == nil {
            torrent_file_priority(Int32(item.torrentIndex), Int32(item.fileIndex), priority)
        } else {
            for child in item.children! {
                setPriority(item: child, priority: priority)
            }
        }
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _item = item as? TorrentContentItem {
            if (_item.children?.count ?? 0) > 0 {
                return true
            }
        }

        return false
    }

    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return content.count
        } else {
            if let _item = item as? TorrentContentItem {
                return _item.children?.count ?? 0
            }
        }

        return 0
    }

    func outlineView(_: NSOutlineView, child: Int, ofItem item: Any?) -> Any {
        if item != nil {
            if let _item = item as? TorrentContentItem {
                return _item.children![child]
            }
        }

        return content[child]
    }

    func outlineView(_: NSOutlineView, objectValueFor col: NSTableColumn?, byItem item: Any?) -> Any? {
        if item != nil, col != nil {
            if let _item = item as? TorrentContentItem {
                switch col!.title {
                case "Name":
                    return _item
                case "Priority":
                    if _item.children == nil {
                        return _item.priority
                    } else {
                        return nil
                    }
                case "Size":
                    if _item.children == nil {
                        return _item.size
                    } else {
                        return nil
                    }
                case "Progress":
                    if _item.children == nil {
                        return _item.progress
                    } else {
                        return nil
                    }
                case "Remaining":
                    if _item.children == nil {
                        return _item.remaining
                    } else {
                        return nil
                    }
                default:
                    return nil
                }
            }
        }

        return nil
    }
}
