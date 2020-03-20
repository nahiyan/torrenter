//
//  UploadRateLimitViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/20/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class UploadRateLimitViewController: NSViewController {
    @IBOutlet var uploadRateLimit: NSTextField!
    @IBOutlet weak var uploadRateLimitUnit: NSPopUpButton!
    @IBOutlet var unlimited: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        let torrent: Torrent = (viewController.torrents.arrangedObjects as! [Torrent])[viewController.torrentsTable.clickedRow]

        if torrent.info.upload_limit == -1 {
            uploadRateLimit.isEnabled = false
            unlimited.state = .on
        } else {
            uploadRateLimit.isEnabled = true
            uploadRateLimit.intValue = Int32(torrent.info.upload_limit)
            unlimited.state = .off
        }
    }

    @IBAction func cancel(_: Any) {
        endSheet(.cancel)
    }

    private func endSheet(_ returnCode: NSApplication.ModalResponse = .OK) {
        let window: NSWindow = view.window!
        NSApplication.shared.mainWindow!.endSheet(window, returnCode: returnCode)
    }

    @IBAction func unlimitedToggle(_: Any) {
        if unlimited.state == .on {
            uploadRateLimit.isEnabled = false
        } else {
            uploadRateLimit.isEnabled = true
        }
    }

    @IBAction func set(_: Any) {
        endSheet()
    }
}
