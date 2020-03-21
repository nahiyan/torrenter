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
    @IBOutlet var uploadRateLimitUnit: NSPopUpButton!
    @IBOutlet var unlimited: NSButton!
    var limit: Int32 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        let viewController: ViewController = NSApplication.shared.mainWindow!.contentViewController as! ViewController

        let torrent: Torrent = (viewController.torrents.arrangedObjects as! [Torrent])[viewController.torrentsTable.clickedRow]

        if limit <= 0 {
            uploadRateLimit.isEnabled = false
            uploadRateLimitUnit.isEnabled = false
            unlimited.state = .on
        } else {
            uploadRateLimit.isEnabled = true
            uploadRateLimitUnit.isEnabled = true

            let data: Data = UnitConversion.dataAutoDiscrete(Float(limit))
            uploadRateLimit.intValue = Int32(data.value)

            switch data.unit {
            case "B":
                uploadRateLimitUnit.selectItem(at: 0)
            case "kB":
                uploadRateLimitUnit.selectItem(at: 1)
            default:
                uploadRateLimitUnit.selectItem(at: 2)
            }

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
            uploadRateLimitUnit.isEnabled = false
        } else {
            uploadRateLimit.isEnabled = true
            uploadRateLimitUnit.isEnabled = true
        }
    }

    @IBAction func set(_: Any) {
        endSheet()
    }
}
