//
//  MainMenu.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 5/18/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa
class MainMenu: NSMenu, NSMenuDelegate {
    private static var _shared: MainMenu?
    static var shared: MainMenu? {
        return _shared
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        MainMenu._shared = self
        delegate = self
        print("Hey")
    }

    func menuWillOpen(_: NSMenu) {
        print("Fuck me")
    }

    func menuDidClose(_: NSMenu) {
        print("Fucked me")
    }

    func menu(_: NSMenu, willHighlight item: NSMenuItem?) {
        print("item fucked")
        if item != nil {
            print(item!.title)
        }
    }
}
