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
        content = []

        super.init(coder: coder)

        delegate = self
        dataSource = self
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
                    return _item.progress
                default:
                    return nil
                }
            }
        }

        return nil
    }
}
