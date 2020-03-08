//
//  MagnetUriViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/6/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class MagnetUriViewController: NSViewController {
    @IBOutlet var magnetUriTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func addMagnetUri(_: Any) {
        endSheet()
    }

    @IBAction func cancel(_: Any) {
        endSheet()
    }

    private func endSheet() {
        let window: NSWindow = view.window!
        NSApplication.shared.mainWindow!.endSheet(window)
    }
}
