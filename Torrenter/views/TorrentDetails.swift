//
//  TorrentDetailsDelegate.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/7/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class TorrentDetails: NSTabView, NSTabViewDelegate {
    enum CurrentTabSelection {
        case general, content, trackers, peers
    }

    var currentTabSelection: CurrentTabSelection

    private var _vc: ViewController?

    var vc: ViewController? {
        if _vc == nil {
            _vc = ViewController.get()
        }

        return _vc
    }

    // Indicates which row the current torrent content data is associated with
    var torrentContentRowAssociativity: Int

    required init?(coder: NSCoder) {
        currentTabSelection = .general
        _vc = nil
        torrentContentRowAssociativity = -1
        super.init(coder: coder)
        delegate = self
    }

    func tabView(_: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if tabViewItem != nil {
            if tabViewItem!.label == "General" {
                currentTabSelection = .general
            } else if tabViewItem!.label == "Content" {
                currentTabSelection = .content
            } else if tabViewItem!.label == "Trackers" {
                currentTabSelection = .trackers
            } else {
                currentTabSelection = .peers
            }

            refresh()
        }

        return true
    }

    func show() {
        if vc != nil {
            vc!.noSelectionIndicator.isHidden = true
            isHidden = false

            refresh()
        }
    }

    func hide() {
        if vc != nil {
            vc!.noSelectionIndicator.isHidden = false
            isHidden = true
        }
    }

    func refresh() {
        if vc == nil {
            return
        }

        switch currentTabSelection {
        case .general:
            if vc!.torrentsTable.selectedRow != -1 {
                let torrent: Torrent = (vc!.torrents.arrangedObjects as! [Torrent])[vc!.torrentsTable.selectedRow]

                // progress bar based on status of pieces
                vc!.piecesProgress.pieces = torrent_pieces(Int32(torrent.index)).content
                vc!.piecesProgress.piecesCount = Int(torrent_pieces(Int32(torrent.index)).count)
                vc!.piecesProgress.needsDisplay = true

                // progress percentage
                vc!.progressPercentage.stringValue = torrent.downloadProgress

                // downloaded
                vc!.downloaded.stringValue = torrent.downloaded

                // uploaded
                vc!.uploaded.stringValue = torrent.uploaded

                // download limit
                vc!.downloadLimit.stringValue = torrent.downloadLimit

                // upload limit
                vc!.uploadLimit.stringValue = torrent.uploadLimit

                // download speed
                vc!.downloadSpeed.stringValue = torrent.downloadRate

                // upload speed
                vc!.uploadSpeed.stringValue = torrent.uploadRate

                // share ratio
                vc!.shareRatio.stringValue = torrent.shareRatio

                // reannounce in
                vc!.reannounceIn.stringValue = torrent.nextAnnounce

                // seeds
                vc!.seedsCount.stringValue = torrent.seeds

                // peers
                vc!.peersCount.stringValue = torrent.peers

                // wasted
                vc!.wasted.stringValue = torrent.wasted

                // connections
                vc!.connections.stringValue = torrent.connections

                // active duration
                vc!.activeDuration.stringValue = torrent.activeDuration

                // time remaining
                vc!.timeRemaining.stringValue = torrent.timeRemaining

                // total size
                vc!.totalSize.stringValue = torrent.size

                // torrent hash
                vc!.torrentHash.stringValue = torrent.infoHash

                // pieces
                vc!.pieces.stringValue = torrent.pieces

                // comment
                vc!.comment.stringValue = torrent.comment

                // created by
                vc!.createdBy.stringValue = torrent.creator

                // save path
                vc!.savePath.stringValue = torrent.savePath
            }
        case .peers:
            // Fetch peers for the selected torrent
            if vc!.torrentsTable.selectedRow != -1 {
                let torrent: Torrent = (vc!.torrents.arrangedObjects as! [Torrent])[vc!.torrentsTable.selectedRow]

                torrent_fetch_peers(Int32(torrent.index))

                let tablePeersCount: Int = (vc!.peers.arrangedObjects as! [Peer]).count
                let actualPeersCount: Int = Int(torrent_peers_count())
                let peersTableSelectedRow: Int = vc!.peersTable.selectedRow

                // Synchronize the table data with the peers list
                if tablePeersCount < actualPeersCount {
                    let beginning = tablePeersCount

                    // print(tablePeersCount, actualPeersCount, beginning)

                    for peerIndex in beginning ..< actualPeersCount {
                        let peer: Peer = Peer(Int(peerIndex))
                        vc!.peers.addObject(peer)
                    }
                } else if tablePeersCount > actualPeersCount {
                    let beginning = actualPeersCount

                    // collect all the peers for removal
                    var peersList: [Peer] = []
                    for peerIndex in beginning ..< tablePeersCount {
                        let peer: Peer = (vc!.peers.arrangedObjects as! [Peer])[peerIndex]
                        peersList.append(peer)
                    }

                    // remove them one by one
                    for peer in peersList {
                        vc!.peers.removeObject(peer)
                    }
                }

                // Refresh peer infos
                for peerIndex in 0 ..< actualPeersCount {
                    let peer: Peer = (vc!.peers.arrangedObjects as! [Peer])[peerIndex]

                    peer.fetchInfo()
                }

                // Reload the peers table
                reloadPeersTable(selectedRow: peersTableSelectedRow)
            }
        case .content:
            if torrentContentRowAssociativity != vc!.torrentsTable.selectedRow {
                // trigger fetch info for all the torrent items
                for item in vc!.torrentContent.content {
                    triggerContentItemRefresh(item)
                }

                reloadContentTable()
                torrentContentRowAssociativity = vc!.torrentsTable.selectedRow
            }

        default: break
        }
    }

    func triggerContentItemRefresh(_ item: TorrentContentItem) {
        item.fetchInfo()
        if item.children != nil {
            for child in item.children! {
                triggerContentItemRefresh(child)
            }
        }
    }

    private func torrentContentItemChildren(items: [ContentItem], item: ContentItem) -> [TorrentContentItem]? {
        if item.isDirectory {
            var children: [TorrentContentItem] = []
            for _item in items {
                if _item.parent == item.id {
                    let torrentContentItem = TorrentContentItem(name: String(cString: _item.name!), fileIndex: Int(_item.file_index), torrentIndex: vc!.torrentsTable.selectedRow)
                    torrentContentItem.children = torrentContentItemChildren(items: items, item: _item)

                    children.append(torrentContentItem)
                }
            }

            return children
        } else {
            return nil
        }
    }

    func reloadContentTable(selectedRow _: Int? = nil) {
        if vc!.torrentsTable.selectedRow != -1 {
            let content: Content = torrent_get_content(Int32(vc!.torrentsTable.selectedRow))

            var items: [ContentItem] = []

            // Clear out outline view
            vc!.torrentContent.content = []

            // Register all the content items
            for i in 0 ..< Int(content.count) {
                let item: ContentItem = content.items![i]!.pointee

                items.append(item)
            }

            // Add the items to the torrent content outline view
            for item in items {
                if item.parent == -1 {
                    let torrentContentItem = TorrentContentItem(name: String(cString: item.name!), fileIndex: Int(item.file_index), torrentIndex: vc!.torrentsTable.selectedRow)
                    torrentContentItem.children = torrentContentItemChildren(items: items, item: item)
                    vc!.torrentContent.content.append(torrentContentItem)
                }
            }

            // reload
            vc!.torrentContent.reloadData()
            for item in vc!.torrentContent.content {
                vc!.torrentContent.expandItem(item, expandChildren: true)
            }

            // free the dynamically allocated memory
            torrent_content_destroy(content)
        }
    }

    func reloadPeersTable(selectedRow: Int? = nil) {
        if vc == nil {
            return
        }

        // Reload table data and retain row selection
        vc!.peersTable.reloadData()

        var _selectedRow: Int
        if selectedRow == nil {
            _selectedRow = vc!.peersTable.selectedRow
        } else {
            _selectedRow = selectedRow!
        }

        vc!.peersTable.selectRowIndexes(IndexSet(integer: _selectedRow), byExtendingSelection: false)
    }
}
