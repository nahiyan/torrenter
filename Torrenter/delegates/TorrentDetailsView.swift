//
//  TorrentDetailsDelegate.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 4/7/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

class TorrentDetailsView: NSTabView, NSTabViewDelegate {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    func tabView(_: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if tabViewItem != nil {
            if tabViewItem!.label == "Peers" {
                print(ViewController.get())
            }
        }

        return true
    }
}
