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
    @IBOutlet var seeds: NSTextField!
    @IBOutlet var peers: NSTextField!
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
            for torrent in self.torrents.arrangedObjects as! [Torrent] {
                torrent.fetchInfo()
            }

            self.reloadTorrentsTable()
            self.refreshDetailsView()

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

    func hideDetails() {
        let detailsView = view.subviews[0].subviews[1]

        for _view in detailsView.subviews {
            _view.isHidden = true
        }

        detailsView.subviews[0].isHidden = false
    }

    func showDetails() {
        let detailsView = view.subviews[0].subviews[1]

        for _view in detailsView.subviews {
            _view.isHidden = false
        }

        detailsView.subviews[0].isHidden = true
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
            if torrent.status == "Downloading" || torrent.status == "Finished" || torrent.status == "Seeding" {
                progressPercentage.stringValue = torrent.progress
            } else {
                progressPercentage.stringValue = "0.0%"
            }

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
            seeds.stringValue = torrent.seeds

            // peers
            peers.stringValue = torrent.peers

            // wasted
            wasted.stringValue = torrent.wasted

            // connections
            connections.stringValue = torrent.connections

            // active duration
            activeDuration.stringValue = torrent.activeDuration

            // time remaining
            timeRemaining.stringValue = torrent.timeRemaining

            // total size
            totalSize.stringValue = "Fuck you all!"
        }
    }
}
