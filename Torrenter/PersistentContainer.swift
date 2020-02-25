//
//  PersistentContainer.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/25/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

import CoreData

class PersistentContainer: NSPersistentContainer {

    func saveContext(backgroundContext: NSManagedObjectContext? = nil) {
        let context = backgroundContext ?? viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            print("Error: \(error), \(error.userInfo)")
        }
    }
}
