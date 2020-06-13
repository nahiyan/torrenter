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
    var torrentDetailsContainerBottomConstraint: NSLayoutConstraint?

    // Indicates which row the current torrent content data is associated with
    var torrentContentRowAssociativity: Int
    var canRefresh: Bool

    required init?(coder: NSCoder) {
        canRefresh = true
        currentTabSelection = .general
        torrentContentRowAssociativity = -1
        torrentDetailsContainerBottomConstraint = nil
        super.init(coder: coder)
        delegate = self
    }

    func tabView(_: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if tabViewItem != nil, ViewController.shared != nil {
            if tabViewItem!.label == "General" {
                currentTabSelection = .general

                // Deactivate the bottom constraint of torrent details container
                deactivateTorrentDetailsContainerBottomConstraint()
            } else if tabViewItem!.label == "Content" {
                currentTabSelection = .content
                activateTorrentDetailsContainerBottomConstraint()
            } else if tabViewItem!.label == "Trackers" {
                currentTabSelection = .trackers
                activateTorrentDetailsContainerBottomConstraint()
            } else {
                currentTabSelection = .peers
                activateTorrentDetailsContainerBottomConstraint()
            }

            refresh()
        }

        return true
    }

    func deactivateTorrentDetailsContainerBottomConstraint() {
        // Deactivate the bottom constraint of torrent details container
        if torrentDetailsContainerBottomConstraint == nil {
            for constraint in ViewController.shared!.torrentDetailsContainer.superview!.constraints {
                if constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
                    torrentDetailsContainerBottomConstraint = constraint
                    constraint.isActive = false
                }
            }
        } else {
            torrentDetailsContainerBottomConstraint!.isActive = false
        }
    }

    func activateTorrentDetailsContainerBottomConstraint() {
        // Activate the bottom constraint of torrent details container
        if torrentDetailsContainerBottomConstraint == nil {
            for constraint in ViewController.shared!.torrentDetailsContainer.superview!.constraints {
                if constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
                    torrentDetailsContainerBottomConstraint = constraint
                    constraint.isActive = true
                }
            }
        } else {
            torrentDetailsContainerBottomConstraint!.isActive = true
        }
    }

    func show() {
        if ViewController.shared != nil {
            ViewController.shared!.splitView.arrangedSubviews[1].isHidden = false

            refresh()
        }
    }

    func hide() {
        if ViewController.shared != nil {
            ViewController.shared!.splitView.arrangedSubviews[1].isHidden = true
        }
    }

    func refresh() {
        if ViewController.shared == nil || !canRefresh {
            return
        }

        switch currentTabSelection {
        case .general:
            if ViewController.shared!.torrentsTable.selectedRow != -1 {
                let torrent: Torrent = ViewController.shared!.torrentsTable.selectedTorrent!

                // progress bar based on status of pieces
                ViewController.shared!.piecesProgress.pieces = torrent_pieces(Int32(torrent.index)).content
                ViewController.shared!.piecesProgress.piecesCount = Int(torrent_pieces(Int32(torrent.index)).count)
                ViewController.shared!.piecesProgress.needsDisplay = true

                // progress percentage
                ViewController.shared!.progressPercentage.stringValue = torrent.downloadProgress

                // progress bar based on availability of pieces
                if ViewController.shared!.piecesAvailability.pieces != nil {
                    free(UnsafeMutableRawPointer(mutating: ViewController.shared!.piecesAvailability.pieces))
                }

                // availability value
                ViewController.shared!.piecesAvailability.pieces = torrent_get_availability(Int32(torrent.index)).content
                ViewController.shared!.piecesAvailability.piecesCount = Int(torrent_get_availability(Int32(torrent.index)).count)
                ViewController.shared!.piecesAvailability.needsDisplay = true

                ViewController.shared!.piecesAvailabilityValue.stringValue = String(format: "%.2f", Float(torrent_get_availability(Int32(torrent.index)).value))

                // downloaded
                ViewController.shared!.downloaded.stringValue = torrent.downloaded

                // uploaded
                ViewController.shared!.uploaded.stringValue = torrent.uploaded

                // download limit
                ViewController.shared!.downloadLimit.stringValue = torrent.downloadLimit

                // upload limit
                ViewController.shared!.uploadLimit.stringValue = torrent.uploadLimit

                // download speed
                ViewController.shared!.downloadSpeed.stringValue = torrent.downloadRate

                // upload speed
                ViewController.shared!.uploadSpeed.stringValue = torrent.uploadRate

                // share ratio
                ViewController.shared!.shareRatio.stringValue = torrent.shareRatio

                // reannounce in
                ViewController.shared!.reannounceIn.stringValue = torrent.nextAnnounce

                // seeds
                ViewController.shared!.seedsCount.stringValue = torrent.seeds

                // peers
                ViewController.shared!.peersCount.stringValue = torrent.peers

                // wasted
                ViewController.shared!.wasted.stringValue = torrent.wasted

                // connections
                ViewController.shared!.connections.stringValue = torrent.connections

                // active duration
                ViewController.shared!.activeDuration.stringValue = torrent.activeDuration

                // time remaining
                ViewController.shared!.timeRemaining.stringValue = torrent.timeRemaining

                // total size
                ViewController.shared!.totalSize.stringValue = torrent.size

                // torrent hash
                ViewController.shared!.torrentHash.stringValue = torrent.infoHash

                // pieces
                ViewController.shared!.pieces.stringValue = torrent.pieces

                // comment
                ViewController.shared!.comment.stringValue = torrent.comment

                // created by
                ViewController.shared!.createdBy.stringValue = torrent.creator

                // save path
                ViewController.shared!.savePath.stringValue = Path.pathAuto(torrent.savePath)

                // added on
                ViewController.shared!.addedOn.stringValue = torrent.addedOn

                // created on
                ViewController.shared!.createdOn.stringValue = torrent.createdOn

                // completed on
                ViewController.shared!.completedOn.stringValue = torrent.completedOn
            }
        case .peers:
            // Fetch peers for the selected torrent
            if ViewController.shared!.torrentsTable.selectedRow != -1 {
                let torrent: Torrent = ViewController.shared!.torrentsTable.selectedTorrent!

                torrent_fetch_peers(Int32(torrent.index))

                let peersCount = Int(torrent_peers_count())
                let peersTableSelectedRow: Int = ViewController.shared!.peersTable.selectedRow

                // Remove peers outside the range & take note of creation of new peers
                var peersIndexMap = [Bool](repeating: false, count: peersCount)
                for peer in ViewController.shared!.peers.arrangedObjects as! [Peer] {
                    if peer.index >= peersCount {
                        ViewController.shared!.peers.removeObject(peer)
                    } else {
                        peersIndexMap[peer.index] = true
                    }
                }

                // Create new peers
                for i in 0 ..< peersCount {
                    if !peersIndexMap[i] {
                        let peer = Peer(i)
                        ViewController.shared!.peers.addObject(peer)
                    }
                }

                for peer in ViewController.shared!.peers.arrangedObjects as! [Peer] {
                    peer.fetchInfo()
                }

                // Reload the peers table
                reloadPeersTable(selectedRow: peersTableSelectedRow)
            }
        case .content:
            if ViewController.shared!.torrentsTable.selectedRow != -1 {
                let torrent: Torrent = ViewController.shared!.torrentsTable.selectedTorrent!

                // Fetch progress (in bytes) of all the torrent files
                torrent_fetch_files_progress(Int32(torrent.index))

                if torrentContentRowAssociativity != ViewController.shared!.torrentsTable.selectedRow { // Only repopulate table if row selection changes
                    repopulateContentTable()
                    torrentContentRowAssociativity = ViewController.shared!.torrentsTable.selectedRow
                } else { // Else just keep reloading it only
                    triggerContentItemsRefresh()
                    reloadContentTable()
                }
            }

        case .trackers:
            if ViewController.shared!.torrentsTable.selectedRow != -1 {
                let trackers: Trackers = torrent_get_trackers(Int32(ViewController.shared!.torrentsTable.selectedTorrent!.index))

                if trackers.count != (ViewController.shared!.trackers.arrangedObjects as! [Tracker]).count {
                    // Clear trackers array
                    for tracker in ViewController.shared!.trackers.arrangedObjects as! [Tracker] {
                        ViewController.shared!.trackers.removeObject(tracker)
                    }

                    // repopulate it
                    for i in 0 ..< Int(trackers.count) {
                        let tracker: Tracker = Tracker(i)
                        ViewController.shared!.trackers.addObject(tracker)
                    }
                } else {
                    for tracker in ViewController.shared!.trackers.arrangedObjects as! [Tracker] {
                        tracker.fetchInfo()
                    }
                }

                reloadTrackersTable()
            }
        }
    }

    func triggerContentItemsRefresh() {
        if ViewController.shared == nil {
            return
        }
        for item in ViewController.shared!.torrentContent.content {
            triggerContentItemRefresh(item)
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
                    let torrentContentItem = TorrentContentItem(name: String(cString: _item.name!), fileIndex: Int(_item.file_index), torrentIndex: ViewController.shared!.torrentsTable.selectedTorrent!.index)
                    torrentContentItem.children = torrentContentItemChildren(items: items, item: _item)

                    children.append(torrentContentItem)
                }
            }

            return children
        } else {
            return nil
        }
    }

    func repopulateContentTable(selectedRow _: Int? = nil) {
        if ViewController.shared!.torrentsTable.selectedRow != -1 {
            let content: Content = torrent_get_content(Int32(ViewController.shared!.torrentsTable.selectedTorrent!.index))

            var items: [ContentItem] = []

            // Clear out outline view
            ViewController.shared!.torrentContent.content = []

            // Register all the content items
            for i in 0 ..< Int(content.count) {
                let item: ContentItem = content.items![i]!.pointee

                items.append(item)
            }

            // Add the items to the torrent content outline view
            for item in items {
                if item.parent == -1 {
                    let torrentContentItem = TorrentContentItem(name: String(cString: item.name!), fileIndex: Int(item.file_index), torrentIndex: ViewController.shared!.torrentsTable.selectedTorrent!.index)

                    torrentContentItem.children = torrentContentItemChildren(items: items, item: item)

                    ViewController.shared!.torrentContent.content.append(torrentContentItem)
                }
            }

            // reload
            reloadContentTable()

            // expand all the items by default
            for item in ViewController.shared!.torrentContent.content {
                ViewController.shared!.torrentContent.expandItem(item, expandChildren: true)
            }

            // free the dynamically allocated memory
            torrent_content_destroy(content)
        }
    }

    func reloadTrackersTable() {
        if ViewController.shared == nil {
            return
        }

        let selectedRow: Int = ViewController.shared!.trackersTable.selectedRow

        ViewController.shared!.trackersTable.reloadData()

        ViewController.shared!.trackersTable.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    }

    func reloadContentTable() {
        if ViewController.shared == nil {
            return
        }

        let selectedRow: Int = ViewController.shared!.torrentContent.selectedRow

        ViewController.shared!.torrentContent.reloadData()

        ViewController.shared!.torrentContent.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    }

    func reloadPeersTable(selectedRow: Int? = nil) {
        if ViewController.shared == nil {
            return
        }

        var _selectedRow: Int
        if selectedRow == nil {
            _selectedRow = ViewController.shared!.peersTable.selectedRow
        } else {
            _selectedRow = selectedRow!
        }

        ViewController.shared!.peers.rearrangeObjects()

        // Reload table data and retain row selection
        ViewController.shared!.peersTable.reloadData()

        ViewController.shared!.peersTable.selectRowIndexes(IndexSet(integer: _selectedRow), byExtendingSelection: false)
    }
}
