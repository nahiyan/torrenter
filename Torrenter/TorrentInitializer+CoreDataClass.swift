//
//  TorrentInitializer+CoreDataClass.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/3/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TorrentInitializer)
public class TorrentInitializer: NSManagedObject {
    
    
    // Clear -> Remove/Delete all
    static func clear(_ container: NSPersistentContainer) -> Void {
        // Remove all torrent initializers
        do {
            let torrentInitializers: [TorrentInitializer] = try container.viewContext.fetch(TorrentInitializer.fetchRequest()) as! [TorrentInitializer]
            
            torrentInitializers.forEach{ torrentInitializer in
                container.viewContext.delete(torrentInitializer)
            }
            
            try container.viewContext.save()
        } catch {
            print("Failed to load torrent initializers")
        }
    }
    
    // Fetch all the torrent initializers in an array
    static func getAll(_ container: NSPersistentContainer) -> [TorrentInitializer] {
        // Load torrent initializers
        do {
            let torrentInitializers: [TorrentInitializer] = try container.viewContext.fetch(TorrentInitializer.fetchRequest()) as! [TorrentInitializer]
            
            return torrentInitializers
        } catch {
            print("Failed to load torrent initializers")
        }
        
        // Return nothing if it fails
        return []
    }
    
    // Insert a torrent initializer
    static func insert(container: NSPersistentContainer, loadPath: String, savePath: String) -> Void {
        // Save dummy torrent initializer
        let entity: NSEntityDescription = NSEntityDescription.entity(forEntityName: "TorrentInitializer", in: container.viewContext)!
        
        let torrentInitializer = NSManagedObject(entity: entity, insertInto: container.viewContext)
        torrentInitializer.setValue(loadPath, forKey: "loadPath")
        torrentInitializer.setValue(savePath, forKey: "savePath")

        do {
            try container.viewContext.save()
        } catch {
            print("Failed to save torrent initializer.")
        }
    }
    
    
}
