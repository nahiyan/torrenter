//
//  AppDelegate.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/16/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        return container
    }()

    func applicationDidFinishLaunching(_: Notification) {
        // Insert code here to initialize your application

        let db = Bundle.main.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "database")
        if db != nil {
            load_geo_ip_database(db!.path)
        }
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
        terminate()
    }
}
