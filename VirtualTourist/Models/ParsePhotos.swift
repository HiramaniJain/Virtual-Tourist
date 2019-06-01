//
//  ParsePhotos.swift
//  VirtualTourist
//
//  Created by Heeral on 5/27/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation


struct ParsePhotos: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let pages: Int
    let photo: [ParsePhoto]
}

struct ParsePhoto: Codable {
    
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url_n"
        case title
    }
}
