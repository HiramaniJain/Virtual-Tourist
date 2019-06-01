//
//  Marker.swift
//  VirtualTourist
//
//  Created by Heeral on 5/25/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation
import CoreData


extension Marker {
    
    static let name = "Marker"
    
    convenience init(latitude: String, longitude: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: Marker.name, in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
}
