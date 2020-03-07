//
//  TorrentInitializer+CoreDataProperties.swift
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/3/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//
//

import Foundation
import CoreData


extension TorrentInitializer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TorrentInitializer> {
        return NSFetchRequest<TorrentInitializer>(entityName: "TorrentInitializer")
    }

    @NSManaged public var magnetUri: String?
    @NSManaged public var loadPath: String?
    @NSManaged public var savePath: String
    @NSManaged public var status: String?
    
}
