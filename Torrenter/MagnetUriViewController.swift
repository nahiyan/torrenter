//
//  MagnetUriViewController.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/6/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class MagnetUriViewController: NSViewController {
    @IBOutlet weak var magnetUriTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func addMagnetUri(_ sender: Any) {
        self.endSheet()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.endSheet()
    }
    
    private func endSheet() {
        let window: NSWindow = self.view.window!
        NSApplication.shared.mainWindow!.endSheet(window)
    }
}
