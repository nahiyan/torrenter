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

    required init?(coder: NSCoder) {
        currentTabSelection = .general
        _vc = nil
        super.init(coder: coder)
        delegate = self

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.refresh()
        }
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
        default: break
        }
    }
}
