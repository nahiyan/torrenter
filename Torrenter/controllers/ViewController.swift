//
//  ViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/16/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    private static var _get: ViewController?

    static var shared: ViewController? {
        return _get
    }

    @IBOutlet var torrents: NSArrayController!
    @IBOutlet var torrentsTable: TorrentsTable!
    var container: NSPersistentContainer!

    @IBOutlet var peers: NSArrayController!
    @IBOutlet var peersTable: NSTableView!

    @IBOutlet var piecesProgress: CompoundProgressBar!
    @IBOutlet var progressPercentage: NSTextField!

    @IBOutlet var piecesAvailability: CompoundProgressBar!
    @IBOutlet var piecesAvailabilityValue: NSTextField!

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
    @IBOutlet var torrentContent: TorrentContent!
    @IBOutlet var trackersTable: NSTableView!
    @IBOutlet var torrentDetailsContainer: TorrentDetailsContainer!
    @IBOutlet var torrentDetails: TorrentDetails!
    @IBOutlet var trackers: NSArrayController!
    @IBOutlet var splitView: NSSplitView!

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController._get = self

        // Set the app data dir
        let appDataDir: String = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Application Support", isDirectory: true).appendingPathComponent("Torrenter", isDirectory: true).relativePath
        set_app_data_dir(appDataDir)

        // Set settings
        configure_libtorrent()

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
            self.torrentsTable.reload()

            // Refresh the torrent details view
            self.torrentDetails.refresh()

            // Save resume data of all torrents (if necessary)
            save_all_resume_data()
        }

        // No selection by default
        torrentDetails.hide()
        torrentDetails.deactivateTorrentDetailsContainerBottomConstraint()

        // Begin listening & responding to alerts
        spawn_alert_monitor()
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

            // Remove button
            removeButton.isEnabled = true

            // Sequential-download toggle button
            sequentialDownloadToggleButton.isEnabled = true
            if torrent.isSequential {
                sequentialDownloadToggleButton.image = NSImage(named: "sort_ascend_active")
            } else {
                sequentialDownloadToggleButton.image = NSImage(named: "sort_ascend")
            }

            // Show details of the torrent and refresh content
            torrentDetails.show()

            // Force refresh to reduce delay of change of progress bar color scheme after selection
            refreshProgressBars()
        } else {
            windowController.deactivateButtons()

            // Hide details of the torrent
            torrentDetails.hide()

            // Force refresh to reduce delay of change of progress bar color scheme after deselection
            refreshProgressBars()
        }
    }

    static func get() -> ViewController? {
        return _get
    }
}

extension ViewController {
    func refreshProgressBars() {
        // Refresh the progress bars
        if torrentsTable.numberOfRows > 0 {
            for rowIndex in 0 ... (torrentsTable.numberOfRows - 1) {
                let torrent: Torrent = (torrents.arrangedObjects as! [Torrent])[rowIndex]

                let progressColumnIndex: Int = torrentsTable.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "progress"))

                let progressBar: SimpleProgressBar = torrentsTable.view(atColumn: progressColumnIndex, row: rowIndex, makeIfNecessary: true)!.subviews[0] as! SimpleProgressBar

                progressBar.progress = torrent.info.progress
                progressBar.needsDisplay = true
            }
        }
    }
}
