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

    required init?(coder: NSCoder) {
        let srcDir = TorrentContentItem("src")

        let mainJava = TorrentContentItem("main.java")
        let mainCpp = TorrentContentItem("main.cpp")

        srcDir.children.append(mainJava)
        srcDir.children.append(mainCpp)

        content = [srcDir]

        super.init(coder: coder)

        delegate = self
        dataSource = self
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _item = item as? TorrentContentItem {
            if _item.children.count > 0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return content.count
        } else {
            if let _item = item as? TorrentContentItem {
                return _item.children.count
            }
        }

        return 0
    }

    func outlineView(_: NSOutlineView, child: Int, ofItem item: Any?) -> Any {
        if item != nil {
            if let _item = item as? TorrentContentItem {
                return _item.children[child]
            }
        }
        return TorrentContentItem("undefined")
    }

    func outlineView(_: NSOutlineView, objectValueFor col: NSTableColumn?, byItem item: Any?) -> Any? {
        if item != nil, col != nil {
            if col!.title == "Name" {
                if let _item = item as? TorrentContentItem {
                    return _item.name
                }
            }
        }
        return nil
    }
}
