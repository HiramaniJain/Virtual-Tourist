//
//  PhotoView.swift
//  VirtualTourist
//
//  Created by Heeral on 5/27/19.
//  Copyright © 2019 heeral. All rights reserved.
//

import Foundation

import UIKit

class PhotoView: UICollectionViewCell {
    static let identifier = "PhotoView"
    
    var imageUrl: String = ""
    
    @IBOutlet weak var tickButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
}
