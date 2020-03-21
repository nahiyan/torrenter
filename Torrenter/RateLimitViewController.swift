//
//  UploadRateLimitViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/20/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class RateLimitViewController: NSViewController {
    @IBOutlet var rateLimit: NSTextField!
    @IBOutlet var isUnlimited: NSButton!
    @IBOutlet var rateLimitUnit: NSPopUpButton!

    private var _limit: Int32 = 0

    var limit: Int32 {
        set {
            _limit = newValue

            updateViews()
        }

        get {
            return _limit
        }
    }

    func updateViews() {
        if limit <= 0 {
            rateLimit.isEnabled = false
            rateLimitUnit.isEnabled = false
            isUnlimited.state = .on
        } else {
            rateLimit.isEnabled = true
            rateLimitUnit.isEnabled = true

            let data: Data = UnitConversion.dataAutoDiscrete(Float(limit))
            rateLimit.intValue = Int32(data.value)

            switch data.unit {
            case "B":
                rateLimitUnit.selectItem(at: 0)
            case "kB":
                rateLimitUnit.selectItem(at: 1)
            default:
                rateLimitUnit.selectItem(at: 2)
            }

            isUnlimited.state = .off
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func cancel(_: Any) {
        endSheet(.cancel)
    }

    private func endSheet(_ returnCode: NSApplication.ModalResponse = .OK) {
        let window: NSWindow = view.window!
        NSApplication.shared.mainWindow!.endSheet(window, returnCode: returnCode)
    }

    @IBAction func unlimitedToggle(_: Any) {
        if isUnlimited.state == .on {
            rateLimit.isEnabled = false
            rateLimitUnit.isEnabled = false
        } else {
            rateLimit.isEnabled = true
            rateLimitUnit.isEnabled = true
        }
    }

    @IBAction func set(_: Any) {
        endSheet()
    }
}
