//
//  MagnetUriViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/6/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class MagnetUriViewController: NSViewController {
    @IBOutlet var magnetUriTextArea: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func addMagnetUri(_: Any) {
        endSheet()
    }

    @IBAction func cancel(_: Any) {
        endSheet(.cancel)
    }

    private func endSheet(_ returnCode: NSApplication.ModalResponse = .OK) {
        let window: NSWindow = view.window!
        NSApplication.shared.mainWindow!.endSheet(window, returnCode: returnCode)
    }
}
