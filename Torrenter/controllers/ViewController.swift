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
    @IBOutlet var torrentsTable: NSTableView!
    var container: NSPersistentContainer!

    @IBOutlet var peers: NSArrayController!
    @IBOutlet var peersTable: NSTableView!

    @IBOutlet var piecesProgress: CompoundProgressBar!
    @IBOutlet var progressPercentage: NSTextField!

    @IBOutlet var downloaded: NSTextField!
    @IBOutlet var downloadLimit: NSTextField!
    @IBOutlet var uploadLimit: NSTextField!
    @IBOutlet var uploadSpeed: NSTextField!
    @IBOutlet var downloadSpeed: NSTextField!
    @IBOutlet var shareRatio: NSTextField!
    @IBOutlet var uploaded: NSTextField!
    @IBOutlet var reannounceIn: NSTextField!
    @IBOutlet var seedsCount: NSTextField!
    @IBOutlet var peersCount: NSTextField!
    @IBOutlet var connections: NSTextField!
    @IBOutlet var wasted: NSTextField!
    @IBOutlet var activeDuration: NSTextField!
    @IBOutlet var timeRemaining: NSTextField!

    @IBOutlet var totalSize: NSTextField!
    @IBOutlet var addedOn: NSTextField!
    @IBOutlet var torrentHash: NSTextField!
    @IBOutlet var savePath: NSTextField!
    @IBOutlet var comment: NSTextField!
    @IBOutlet var pieces: NSTextField!
    @IBOutlet var completedOn: NSTextField!
    @IBOutlet var createdBy: NSTextField!
    @IBOutlet var createdOn: NSTextField!

    @IBOutlet var torrentDetails: NSTabView!
    @IBOutlet var noSelectionIndicator: NSTextField!

    let contextMenu: NSMenu = NSMenu()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        let delegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        container = delegate.persistentContainer

        guard container != nil else {
            fatalError("This view needs a persistent container.")
        }

        // Set the app data dir
        let appDataDir: String = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Application Support", isDirectory: true).appendingPathComponent("Torrenter", isDirectory: true).relativePath
        set_app_data_dir(appDataDir)

        // Load torrents from resume data
        let resumeDataDir: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Application Support", isDirectory: true).appendingPathComponent("Torrenter", isDirectory: true).appendingPathComponent("resume_files", isDirectory: true)

        do {
            let resumeFileNames: [String] = try FileManager.default.contentsOfDirectory(atPath: resumeDataDir.relativePath)

            for resumeFileName in resumeFileNames {
                let fileNameComponents: [String] = resumeFileName.components(separatedBy: ".")

                if fileNameComponents[fileNameComponents.count - 1] == "resume" {
                    // Initiate the torrent
                    torrent_initiate_resume_data(resumeFileName)

                    // Add torrent to list
                    let torrent: Torrent = Torrent(Int(torrent_next_index() - 1))
                    torrents.addObject(torrent)
                }
            }
        } catch {
            print("Error trying to read torrent resume files.")
        }

        // Initial progress bar refresh
        refreshProgressBars()

        // refresh the data periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Fetch torrent info
            for torrent in self.torrents.arrangedObjects as! [Torrent] {
                torrent.fetchInfo()
            }

            // Reload torrents table
            self.reloadTorrentsTable()

            // Refresh details view
            self.refreshDetailsView()

            // Fetch peers for the selected torrent
            if self.torrentsTable.selectedRow != -1 {
                let torrent: Torrent = (self.torrents.arrangedObjects as! [Torrent])[self.torrentsTable.selectedRow]

                torrent_fetch_peers(Int32(torrent.index))

                // Clear the current array
                for peer in self.peers.arrangedObjects as! [Peer] {
                    self.peers.removeObject(peer)
                }

                // Repopulate the array
                for peer_index in 0 ..< torrent_peers_count() {
                    let peer: Peer = Peer(Int(peer_index), torrent_get_peer_info(Int32(peer_index)))
                    self.peers.addObject(peer)
                }

                // Reload the peers table
                self.reloadPeersTable()
            }

            // Save resume data of all torrents (if necessary)
            save_all_resume_data()
        }

        // No selection by default
        hideDetails()

        // Begin listening & responding to alerts
        spawn_alert_monitor()

        // Attach context menu
        initiateContextMenu()
        torrentsTable.menu = contextMenu
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func tableClicked(_: Any) {
        updateActionButtonsAndDetailsView()
    }

    func updateActionButtonsAndDetailsView() {
        let windowController: WindowController = NSApplication.shared.mainWindow!.windowController as! WindowController
        let pauseResumeButton: NSButton = windowController.pauseResumeButton
        let stopButton: NSButton = windowController.stopButton
        let removeButton: NSButton = windowController.removeButton
        let sequentialDownloadToggleButton: NSButton = windowController.sequentialDownloadToggleButton

        if torrentsTable.selectedRow != -1 {
            let torrent: Torrent = (torrents.arrangedObjects as! [Torrent])[torrentsTable.selectedRow]

            // Play/pause button
            pauseResumeButton.isEnabled = true
            if torrent.isPaused {
                pauseResumeButton.image = NSImage(named: "play")
            } else {
                pauseResumeButton.image = NSImage(named: "pause")
            }

            // Stop button
            if torrent.isFinished, !torrent.isSeeding {
                stopButton.isEnabled = false
            } else {
                stopButton.isEnabled = true
            }

            // Remove button
            removeButton.isEnabled = true

            // Sequential-download toggle button
            sequentialDownloadToggleButton.isEnabled = true
            if torrent.isSequential {
                sequentialDownloadToggleButton.image = NSImage(named: "sort_ascend_active")
            } else {
                sequentialDownloadToggleButton.image = NSImage(named: "sort_ascend")
            }

            // Show details of the torrent
            showDetails()

            // Force refresh to reduce delay of change of progress bar color scheme after selection
            refreshProgressBars()
        } else {
            windowController.deactivateButtons()

            // Hide details of the torrent
            hideDetails()

            // Force refresh to reduce delay of change of progress bar color scheme after deselection
            refreshProgressBars()
        }
    }

    static func get() -> ViewController {
        return NSApplication.shared.mainWindow!.contentViewController as! ViewController
    }
}

extension ViewController {
    func initiateContextMenu() {
        contextMenu.addItem(withTitle: "Pause", action: nil, keyEquivalent: "")
        contextMenu.addItem(withTitle: "Remove", action: nil, keyEquivalent: "")
        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(withTitle: "Limit Download Rate", action: nil, keyEquivalent: "")
        contextMenu.addItem(withTitle: "Limit Upload Rate", action: nil, keyEquivalent: "")
        contextMenu.addItem(withTitle: "Limit Share Ratio", action: nil, keyEquivalent: "")
        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(withTitle: "Download in Sequential Order", action: nil, keyEquivalent: "")
        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(withTitle: "Force Recheck", action: nil, keyEquivalent: "")
        contextMenu.addItem(withTitle: "Force Reannounce", action: nil, keyEquivalent: "")
        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(withTitle: "Open Destination Directory", action: nil, keyEquivalent: "")
    }

    func reloadTorrentsTable() {
        let selectedRow = torrentsTable.selectedRow

        // Reload table data and retain row selection
        torrentsTable.reloadData()
        torrentsTable.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)

        // Refresh progress bars
        refreshProgressBars()
    }

    func reloadPeersTable() {
        let selectedRow = peersTable.selectedRow

        // Reload table data and retain row selection
        peersTable.reloadData()
        peersTable.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    }

    func hideDetails() {
        noSelectionIndicator.isHidden = false
        torrentDetails.isHidden = true
    }

    func showDetails() {
        noSelectionIndicator.isHidden = true
        torrentDetails.isHidden = false

        refreshDetailsView()
    }

    func refreshProgressBars() {
        // Refresh the progress bars
        for rowIndex in 0 ... (torrentsTable.numberOfRows - 1) {
            let torrent: Torrent = (torrents.arrangedObjects as! [Torrent])[rowIndex]

            let progressColumnIndex: Int = torrentsTable.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "progress"))

            let progressBar: SimpleProgressBar = torrentsTable.view(atColumn: progressColumnIndex, row: rowIndex, makeIfNecessary: true)!.subviews[0] as! SimpleProgressBar

            progressBar.progress = torrent.info.progress
            progressBar.needsDisplay = true
        }
    }

    func refreshDetailsView() {
        if torrentsTable.selectedRow != -1 {
            let torrent: Torrent = (torrents.arrangedObjects as! [Torrent])[torrentsTable.selectedRow]

            // progress bar based on status of pieces
            piecesProgress.pieces = torrent_pieces(Int32(torrent.index)).content
            piecesProgress.piecesCount = Int(torrent_pieces(Int32(torrent.index)).count)
            piecesProgress.needsDisplay = true

            // progress percentage
            progressPercentage.stringValue = torrent.downloadProgress

            // downloaded
            downloaded.stringValue = torrent.downloaded

            // uploaded
            uploaded.stringValue = torrent.uploaded

            // download limit
            downloadLimit.stringValue = torrent.downloadLimit

            // upload limit
            uploadLimit.stringValue = torrent.uploadLimit

            // download speed
            downloadSpeed.stringValue = torrent.downloadRate

            // upload speed
            uploadSpeed.stringValue = torrent.uploadRate

            // share ratio
            shareRatio.stringValue = torrent.shareRatio

            // reannounce in
            reannounceIn.stringValue = torrent.nextAnnounce

            // seeds
            seedsCount.stringValue = torrent.seeds

            // peers
            peersCount.stringValue = torrent.peers

            // wasted
            wasted.stringValue = torrent.wasted

            // connections
            connections.stringValue = torrent.connections

            // active duration
            activeDuration.stringValue = torrent.activeDuration

            // time remaining
            timeRemaining.stringValue = torrent.timeRemaining

            // total size
            totalSize.stringValue = torrent.size

            // torrent hash
            torrentHash.stringValue = torrent.infoHash

            // pieces
            pieces.stringValue = torrent.pieces

            // comment
            comment.stringValue = torrent.comment

            // created by
            createdBy.stringValue = torrent.creator

            // save path
            savePath.stringValue = torrent.savePath
        }
    }
}