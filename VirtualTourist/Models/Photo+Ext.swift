//
//  Photo+Ext.swift
//  VirtualTourist
//
//  Created by Heeral on 5/27/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    
    static let name = "Photo"
    
    convenience init(title: String, imageUrl: String, forMarker: Marker, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: Photo.name, in: context) {
            self.init(entity: entity, insertInto: context)
            self.title = title
            self.image = nil
            self.imageUrl = imageUrl
            self.marker = forMarker
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
